'use strict';

/* global MathQuill, bootstrap */

(() => {
	// Global list of all MathQuill answer inputs.
	window.answerQuills = {};

	// initialize MathQuill
	const MQ = MathQuill.getInterface();

	const setupMQInput = (mq_input) => {
		if (mq_input.dataset.mqEditorInitialized) return;
		mq_input.dataset.mqEditorInitialized = 'true';

		const answerLabel = mq_input.id.replace(/^MaThQuIlL_/, '');
		const input = document.getElementById(answerLabel);
		const inputType = input?.type;
		if (
			typeof inputType !== 'string' ||
			((inputType.toLowerCase() !== 'text' || !input.classList.contains('codeshard')) &&
				(inputType.toLowerCase() !== 'textarea' || !input.classList.contains('latexentryfield')))
		)
			return;

		const answerQuill = document.createElement('span');
		answerQuill.id = `mq-answer-${answerLabel}`;
		answerQuill.input = input;
		input.classList.add('mq-edit');
		answerQuill.latexInput = mq_input;

		// Give the mathquill answer box the correct/incorrect colors.
		if (input.classList.contains('correct')) answerQuill.classList.add('correct');
		if (input.classList.contains('incorrect')) answerQuill.classList.add('incorrect');
		if (input.classList.contains('partially-correct')) answerQuill.classList.add('partially-correct');

		// Default options.
		const cfgOptions = {
			enableSpaceNavigation: true,
			leftRightIntoCmdGoes: 'up',
			restrictMismatchedBrackets: true,
			sumStartsWithNEquals: true,
			supSubsRequireOperand: true,
			autoCommands: ['pi', 'sqrt', 'root', 'vert', 'inf', 'union', 'abs', 'deg', 'AA', 'angstrom', 'ln', 'log']
				.concat(
					['sin', 'cos', 'tan', 'sec', 'csc', 'cot'].reduce((a, t) => a.concat([t, `arc${t}`, `a${t}`]), [])
				)
				.join(' '),
			rootsAreExponents: true,
			logsChangeBase: true,
			useToolbar: true,
			maxDepth: 10
		};

		// Merge options that are set by the problem.
		if (answerQuill.latexInput.dataset.mqOpts)
			Object.assign(cfgOptions, JSON.parse(answerQuill.latexInput.dataset.mqOpts));

		cfgOptions.handlers = {};

		const latexEntryMode = input.classList.contains('latexentryfield');

		if (latexEntryMode) {
			// Wrap the input in a container and inner container.
			const container = document.createElement('div');
			container.classList.add('mq-latex-editor-container');
			input.after(container);

			const innerContainer = document.createElement('div');
			innerContainer.classList.add('mq-latex-editor-inner-container');
			container.append(innerContainer);

			const textAreaContainer = document.createElement('div');
			textAreaContainer.classList.add('mq-latex-editor-textarea-container');
			innerContainer.append(textAreaContainer);

			const backdropContainer = document.createElement('div');
			backdropContainer.classList.add('mq-latex-editor-backdrop-container');
			const backdrop = document.createElement('div');
			backdrop.classList.add('mq-latex-editor-backdrop');
			backdropContainer.append(backdrop);
			textAreaContainer.append(backdropContainer, input);

			const beforeSelection = document.createElement('span');
			const selection = document.createElement('mark');
			selection.classList.add('mq-latex-editor-selection');
			const afterSelection = document.createElement('span');
			const endMark = document.createElement('mark');
			backdrop.append(beforeSelection, selection, afterSelection, endMark);

			const updateScroll = () => {
				backdropContainer.scrollTop = input.scrollTop;
				backdropContainer.scrollLeft = input.scrollLeft;
			};
			const setSelection = () => {
				beforeSelection.textContent = input.value.substring(0, input.selectionStart);
				selection.textContent = input.value.substring(input.selectionStart, input.selectionEnd);
				afterSelection.textContent = input.value.substring(input.selectionEnd, input.value.length);
				updateScroll();
			};
			const clearSelection = () => {
				beforeSelection.textContent = input.value.substring(0, input.selectionStart);
				selection.textContent = '';
				afterSelection.textContent = input.value.substring(input.selectionStart, input.value.length);
			};
			input.addEventListener('keydown', clearSelection);
			input.addEventListener('keyup', setSelection);
			input.addEventListener('pointerdown', clearSelection);
			input.addEventListener('pointerup', setSelection);
			input.addEventListener('scroll', updateScroll);

			// Create and add a button to activate the MathQuill editor.
			const button = document.createElement('button');
			button.type = 'button';
			button.classList.add('btn', 'btn-sm', 'btn-secondary', 'mq-latex-editor-btn');
			button.dataset.bsToggle = 'collapse';
			button.dataset.bsTarget = `#${answerLabel}-equation-editor`;
			button.setAttribute('aria-expanded', 'false');
			button.setAttribute('aria-controls', `${answerLabel}-equation-editor`);
			button.setAttribute('aria-label', 'Equation Editor');

			const icon = document.createElement('i');
			icon.classList.add('fa-solid', 'fa-square-root-variable');
			button.append(icon);

			// Find the preview button container, and add the equation editor button to that.
			const buttonContainer = document.getElementById(`${answerLabel}-latexentry-button-container`);
			if (buttonContainer) {
				buttonContainer.classList.add('d-flex', 'gap-2');
				buttonContainer.prepend(button);
				innerContainer.append(buttonContainer);
			} else {
				innerContainer.append(button);
			}

			// Create a collapse to hold the editor.
			const collapse = document.createElement('div');
			collapse.classList.add('collapse', 'mt-2');
			collapse.id = `${answerLabel}-equation-editor`;

			let blinkInterval;
			const blink = () => backdrop.classList.toggle('mq-latex-editor-backdrop-blink');
			collapse.addEventListener('focusin', () => {
				setSelection();
				backdrop.classList.add('mq-latex-editor-backdrop-show');
				blinkInterval = setInterval(blink, 1000);
			});
			collapse.addEventListener('focusout', () => {
				clearInterval(blinkInterval);
				backdrop.classList.remove('mq-latex-editor-backdrop-show', 'mq-latex-editor-backdrop-blink');
			});

			const contents = document.createElement('div');
			contents.classList.add('card');

			const cardHeader = document.createElement('div');
			cardHeader.classList.add(
				'card-header',
				'd-flex',
				'justify-content-between',
				'align-items-center',
				'px-2',
				'py-1',
				'text-bg-secondary'
			);

			const title = document.createElement('span');
			title.textContent = 'Equation Editor';

			const closeButton = document.createElement('button');
			// When bootstrap is upgraded to version 5.3 this will need to be changed.
			// btn-close-white will be deprecated and data-bs-theme="dark" is used instead.
			closeButton.classList.add('btn-close', 'btn-close-white');
			closeButton.type = 'button';
			closeButton.setAttribute('aria-label', 'Close');
			closeButton.dataset.bsToggle = 'collapse';
			closeButton.dataset.bsTarget = `#${answerLabel}-equation-editor`;

			cardHeader.append(title, closeButton);

			const cardBody = document.createElement('div');
			cardBody.classList.add('card-body', 'p-2', 'd-flex', 'align-items-center');
			cardBody.append(answerQuill);

			// Insert text at a the current cursor position in a text input replacing the current selection if any.
			const insertAtCursor = (input, myValue) => {
				if (input.selectionStart) {
					const startPos = input.selectionStart;
					const endPos = input.selectionEnd;
					const scrollTop = input.scrollTop;
					input.value = `${input.value.substring(0, startPos)}${myValue}${input.value.substring(
						endPos,
						input.value.length
					)}`;
					input.focus();
					input.selectionStart = startPos + myValue.length;
					input.selectionEnd = startPos + myValue.length;
					input.scrollTop = scrollTop;
				} else {
					input.value += myValue;
					input.focus();
				}
				setSelection();
			};

			const cardFooter = document.createElement('div');
			cardFooter.classList.add(
				'card-footer',
				'd-flex',
				'pt-0',
				'pb-2',
				'px-2',
				'gap-2',
				'bg-white',
				'border-top-0'
			);

			const insertButton = document.createElement('button');
			insertButton.type = 'button';
			insertButton.classList.add('btn', 'btn-sm', 'btn-primary');
			insertButton.textContent = 'Insert';
			insertButton.addEventListener('click', () => {
				const latex = answerQuill.mathField.latex().replace(/^(?:\\\s)*(.*?)(?:\\\s)*$/, '$1');
				if (latex) insertAtCursor(answerQuill.input, `\\(${latex}\\)`);
			});

			answerQuill.clearButton = document.createElement('button');
			answerQuill.clearButton.type = 'button';
			answerQuill.clearButton.classList.add('btn', 'btn-sm', 'btn-primary');
			answerQuill.clearButton.textContent = 'Clear';
			answerQuill.clearButton.addEventListener('click', () => {
				answerQuill.mathField.empty();
				answerQuill.textarea.focus();
			});

			cardFooter.append(insertButton, answerQuill.clearButton);

			contents.append(cardHeader, cardBody, cardFooter);
			collapse.append(contents);
			innerContainer.append(collapse);

			collapse.addEventListener('shown.bs.collapse', () => answerQuill.textarea.focus());
			collapse.addEventListener('hidden.bs.collapse', () => answerQuill.textarea.blur());
		} else {
			cfgOptions.handlers.edit = (mq) => {
				if (mq.text() !== '') {
					answerQuill.input.value = mq.text().trim();
					answerQuill.latexInput.value = mq.latex().replace(/^(?:\\\s)*(.*?)(?:\\\s)*$/, '$1');
				} else {
					answerQuill.input.value = '';
					answerQuill.latexInput.value = '';
				}

				// If any feedback popovers are open, then update their positions.
				for (const popover of document.querySelectorAll('.ww-feedback-btn')) {
					bootstrap.Popover.getInstance(popover)?.update();
				}
			};

			// Trigger a button press when the enter key is pressed in an answer box.
			cfgOptions.handlers.enter = () => {
				// For ww2 homework if the enter_key_submit button is found, then use that.
				// This Depends on $pg{options}{enterKey}.
				const enterKeySubmit = document.getElementById('enter_key_submit');
				if (enterKeySubmit) {
					enterKeySubmit.click();
					return;
				}
				// If the enter_key_submit button is not found (it will not be present in tests),
				// then use the preview button.
				document.querySelector('input[name=previewAnswers]')?.click();
			};

			input.after(answerQuill);
		}

		answerQuill.mathField = MQ.MathField(answerQuill, cfgOptions);

		answerQuill.textarea = answerQuill.querySelector('textarea');

		if (!cfgOptions.logsChangeBase) {
			answerQuill.mathField.options.addToolbarButtons(
				{
					id: 'subscript',
					latex: '_',
					tooltip: 'subscript (_)',
					icon: '\\text{  }_\\text{  }'
				},
				'exponent'
			);
		}

		if (cfgOptions.includeIonButtons) {
			answerQuill.mathField.options.addToolbarButtons([
				{
					id: 'positiveion',
					latex: '\\positiveion',
					tooltip: 'positive ion',
					icon: '\\text{ }^{\\text{ }+}'
				},
				{
					id: 'negativeion',
					latex: '\\negativeion',
					tooltip: 'negative ion',
					icon: '\\text{ }^{\\text{ }-}'
				}
			]);
		}

		window.answerQuills[answerLabel] = answerQuill;

		if (latexEntryMode) return;

		setTimeout(() => {
			answerQuill.mathField.latex(answerQuill.latexInput.value);
			answerQuill.mathField.moveToLeftEnd();
			answerQuill.mathField.blur();
		}, 100);
	};

	// Set up MathQuill inputs that are already in the page.
	document.querySelectorAll('[id^=MaThQuIlL_]').forEach(setupMQInput);

	// Observer that sets up MathQuill inputs.
	const observer = new MutationObserver((mutationsList) => {
		for (const mutation of mutationsList) {
			for (const node of mutation.addedNodes) {
				if (node instanceof Element) {
					if (node.id && node.id.startsWith('MaThQuIlL_')) {
						setupMQInput(node);
					} else {
						node.querySelectorAll('input[id^=MaThQuIlL_]').forEach(setupMQInput);
					}
				}
			}
		}
	});
	observer.observe(document.body, { childList: true, subtree: true });
})();
