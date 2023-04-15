'use strict';

(() => {
	class MathViewer {
		constructor(field, userOptions) {
			field.dataset.mvInitialized = 'true';

			this.options = Object.assign(
				{
					renderingMode: 'PGML',
					decoratedTextBoxAsInput: true,
					includeDelimiters: false
				},
				userOptions
			);
			this.renderingMode = this.options.renderingMode;

			this.id = `${field.id}_mathviewer`;

			this.decoratedTextBox = field;

			// Wrap the input in a container.
			const container = document.createElement('div');
			container.classList.add('mv-container');
			if (this.options.renderingMode === 'PGML')
				container.classList.add('input-group', 'd-inline-flex', 'flex-nowrap', 'w-auto');
			field.after(container);

			if (this.options.decoratedTextBoxAsInput) {
				container.append(field);
				this.inputTextBox = field;
			} else {
				const textAreaContainer = document.createElement('div');
				textAreaContainer.classList.add('mv-textarea-container');
				container.append(textAreaContainer);

				const backdropContainer = document.createElement('div');
				backdropContainer.classList.add('mv-backdrop-container');
				this.backdrop = document.createElement('div');
				this.backdrop.classList.add('mv-backdrop');
				backdropContainer.append(this.backdrop);
				textAreaContainer.append(backdropContainer, field);

				const beforeSelection = document.createElement('span');
				const selection = document.createElement('mark');
				selection.classList.add('mv-selection');
				const afterSelection = document.createElement('span');
				const endMark = document.createElement('mark');
				this.backdrop.append(beforeSelection, selection, afterSelection, endMark);

				const updateScroll = () => {
					backdropContainer.scrollTop = field.scrollTop;
					backdropContainer.scrollLeft = field.scrollLeft;
				};
				this.setSelection = () => {
					beforeSelection.textContent = field.value.substring(0, field.selectionStart);
					selection.textContent = field.value.substring(field.selectionStart, field.selectionEnd);
					afterSelection.textContent = field.value.substring(field.selectionEnd, field.value.length);
					updateScroll();
				};
				const clearSelection = () => {
					beforeSelection.textContent = field.value.substring(0, field.selectionStart);
					selection.textContent = '';
					afterSelection.textContent = field.value.substring(field.selectionStart, field.value.length);
				};
				field.addEventListener('keydown', clearSelection);
				field.addEventListener('keyup', this.setSelection);
				field.addEventListener('pointerdown', clearSelection);
				field.addEventListener('pointerup', this.setSelection);
				field.addEventListener('scroll', updateScroll);

				this.blink = () => this.backdrop.classList.toggle('mv-backdrop-blink');

				this.inputTextBox = document.createElement('input');
				this.inputTextBox.type = 'text';
				this.inputTextBox.classList.add('mv-input', 'form-control');
			}

			// Create and add a button to activate the math viewer.
			this.button = document.createElement('button');
			this.button.type = 'button';
			this.button.classList.add('btn', 'btn-sm', 'btn-secondary', 'codeshard-btn');
			if (this.options.renderingMode === 'LATEX') this.button.classList.add('latexentryfield-btn');
			this.button.setAttribute('aria-label', 'Equation Editor');

			const icon = document.createElement('i');
			icon.classList.add('fa-solid', this.options.renderingMode === 'PGML' ? 'fa-th' : 'fa-pencil');
			this.button.append(icon);

			container.append(this.button);

			// Create the title bar with title and close button.
			this.popoverTitle = document.createElement('span');
			this.popoverTitle.classList.add('d-flex', 'align-items-center', 'justify-content-between');

			const title = document.createElement('span');
			title.textContent = mathView_translator[7];

			const titleClose = document.createElement('button');
			titleClose.classList.add('btn-close');
			titleClose.type = 'button';
			titleClose.setAttribute('aria-label', 'Close');
			titleClose.addEventListener('click', () => this.popover.hide());

			this.popoverTitle.append(title, titleClose);

			// Add the popover content.
			this.popoverContent = document.createElement('div');

			const dropdownContainer = document.createElement('div');
			dropdownContainer.classList.add('d-flex', 'justify-content-center', 'align-items-center');

			const dropdownNav = document.createElement('ul');
			dropdownNav.classList.add('nav', 'nav-tabs');
			dropdownNav.setAttribute('role', 'tablist');
			dropdownContainer.append(dropdownNav);

			const dropdownNavList = document.createElement('li');
			dropdownNavList.classList.add('dropdown');
			dropdownNavList.setAttribute('role', 'presentation');
			dropdownNav.append(dropdownNavList);

			const dropdownButton = document.createElement('button');
			dropdownButton.type = 'button';
			dropdownButton.classList.add('btn', 'btn-secondary', 'dropdown-toggle');
			dropdownButton.dataset.bsToggle = 'dropdown';
			dropdownButton.setAttribute('aria-expanded', 'false');
			dropdownButton.textContent = mathView_translator[12];

			this.dropdown = document.createElement('ul');
			this.dropdown.classList.add('dropdown-menu');
			this.dropdown.setAttribute('role', 'menu');

			dropdownNavList.append(dropdownButton, this.dropdown);

			this.popoverContent.append(dropdownContainer);

			this.tabContent = document.createElement('div');
			this.tabContent.classList.add('tab-content');
			this.popoverContent.append(this.tabContent);

			// Generate html for each of the categories in the locale file.
			for (const [index, category] of mv_categories.entries()) {
				this.createCat(index, category);
			}

			const card = document.createElement('div');
			card.classList.add('card', 'bg-light', 'p-2', 'overflow-auto');
			this.mviewer = document.createElement('div');
			this.mviewer.classList.add('mviewer', 'd-flex', 'justify-content-center', 'align-items-center');
			this.mviewer.textContent = this.inputTextBox.value;
			card.append(this.mviewer);
			this.popoverContent.append(card);

			if (!this.options.decoratedTextBoxAsInput) {
				const mvInput = document.createElement('div');
				mvInput.classList.add('input-group', 'mt-2');

				const insertButton = document.createElement('button');
				insertButton.type = 'button';
				insertButton.classList.add('btn', 'btn-primary');
				insertButton.textContent = 'Insert';
				insertButton.addEventListener('click', () => {
					let insertstring = this.inputTextBox.value;
					if (this.options.includeDelimiters) insertstring = `\\(${insertstring}\\)`;
					this.insertAtCursor(this.decoratedTextBox, insertstring);
				});

				mvInput.append(this.inputTextBox, insertButton);
				this.popoverContent.append(mvInput);
			}

			// Initialize the popover.
			this.popover = new bootstrap.Popover(this.button, {
				html: true,
				content: this.popoverContent,
				trigger: 'manual',
				placement: 'right',
				title: this.popoverTitle,
				container: container
			});

			this.button.addEventListener('show.bs.popover', () => {
				this.regenPreview();
				MathJax.startup.promise = MathJax.startup.promise.then(() => MathJax.typesetPromise(['.popover']));
			});

			// Refresh math in the popover when there is a keyup in the input.
			// Only do this while the popover is visible.
			const inputRegenPreview = () => this.regenPreview();
			this.button.addEventListener('shown.bs.popover', () => {
				this.inputTextBox.addEventListener('keyup', inputRegenPreview)

				if (!this.options.decoratedTextBoxAsInput) {
					this.popover.tip.addEventListener('focusin', () => {
						this.inputTextBox.focus();
						this.setSelection();
						this.backdrop.classList.add('mv-backdrop-show');
						if (!this.blinkInterval) this.blinkInterval = setInterval(this.blink, 1000);
					});
					this.popover.tip.addEventListener('focusout', () => {
						clearInterval(this.blinkInterval);
						delete this.blinkInterval;
						this.backdrop.classList.remove('mv-backdrop-show', 'mv-backdrop-blink');
					});
					this.popover.tip.dispatchEvent(new Event('focusin'));
				}
			});
			this.button.addEventListener('hide.bs.popover', () => {
				this.popover.tip.dispatchEvent(new Event('focusout'));
				this.inputTextBox.removeEventListener('keyup', inputRegenPreview)
			});

			const closeOther = () => {
				for (const mviewerBtn of document.querySelectorAll('.codeshard-btn')) {
					if (mviewerBtn !== this.button) bootstrap.Popover.getInstance(mviewerBtn)?.hide();
				}
			};

			// Open the popover when the button is clicked.  Close any other open math viewers at this time.
			this.button.addEventListener('click', () => {
				closeOther();
				this.popover.toggle();
			});

			// Close other open math viewers when the input for this math viewer gains focus.
			field.addEventListener('focus', closeOther);
		}

		// Insert the appropriate string into the input box when a button in the viewer is pressed.
		generateTex(strucValue) {
			let newpos = this.inputTextBox.selectionStart;

			if (this.renderingMode === 'LATEX') {
				this.insertAtCursor(this.inputTextBox, strucValue.latex);
				const parmatch = strucValue.latex.match(/\(\)|\[,|\(,/);
				if (parmatch) newpos += parmatch[0].index;
				this.setCursorPosition(this.inputTextBox, newpos);
				this.regenPreview();
			} else {
				this.insertAtCursor(this.inputTextBox, strucValue.PG);
				const parmatch = strucValue.PG.match(/\(\)|\[,|\(,/);
				if (parmatch) newpos += parmatch.index + 1;
				this.setCursorPosition(this.inputTextBox, newpos);
				this.regenPreview();
			}
		}

		// Regenerate the preview in the math viewer whenever the input value changes.
		regenPreview() {
			let text = this.inputTextBox.value.replace(/\*\*/g, '^');

			if (this.renderingMode === 'LATEX') this.mviewer.textContent = `\\(${text}\\)`;
			else this.mviewer.textContent = `\`${text}\``;

			MathJax.startup.promise = MathJax.startup.promise.then(() => MathJax.typesetPromise([this.mviewer]));
		}

		// Create a category from the locale js.  Each category is implemented using bootstraps tab feature.  The
		// selectors for the tab go in a dropdown menu.  The tabs contain a thumbnail grid of the buttons in the
		// category.
		createCat(catCount, catValue) {
			const tabList = document.createElement('ul');
			tabList.classList.add(
				'mvthumbnails',
				'd-flex',
				'flex-wrap',
				'justify-content-evenly',
				'm-0',
				'p-0',
				'list-unstyled'
			);

			for (const [i, value] of catValue.operators.entries()) {
				const listElt = document.createElement('li');
				listElt.classList.add('mvspan3', 'mx-2', 'mb-3');

				const thumbnail = document.createElement('a');
				thumbnail.href = '#';
				thumbnail.classList.add('mvthumbnail', 'text-center');
				thumbnail.textContent = value.text;
				thumbnail.setAttribute('aria-controls', this.decoratedTextBox.id);
				thumbnail.setAttribute('aria-label', value.tooltip);
				thumbnail.dataset.bsToggle = 'tooltip';
				thumbnail.dataset.bsPlacement = 'top';
				thumbnail.addEventListener('click', (e) => {
					e.preventDefault();
					this.generateTex(value);
				});

				listElt.append(thumbnail);

				tabList.append(listElt);

				new bootstrap.Tooltip(thumbnail, { delay: { show: 500, hide: 100 }, title: value.tooltip });
			}

			// Create the tab pane for the category and add the entry to list.
			const tabPane = document.createElement('div');
			tabPane.classList.add('tab-pane', 'fade');
			if (catCount === 0) tabPane.classList.add('active', 'show');
			tabPane.id = `mvtab_${this.id}_${catCount}`;
			tabPane.setAttribute('role', 'tabpanel');
			tabPane.append(tabList);
			this.tabContent.append(tabPane);

			const dropdownLi = document.createElement('li');
			const dropdownItem = document.createElement('a');
			dropdownItem.classList.add('dropdown-item');
			if (catCount === 0) {
				dropdownItem.classList.add('active');
				dropdownItem.setAttribute('aria-expanded', 'true');
			} else {
				dropdownItem.setAttribute('aria-expanded', 'false');
			}
			dropdownItem.href = `#mvtab_${this.id}_${catCount}`;
			dropdownItem.dataset.bsToggle = 'tab';
			dropdownItem.dataset.bsTarget = `#mvtab_${this.id}_${catCount}`;
			dropdownItem.setAttribute('aria-controls', `mvtab_${this.id}_${catCount}`);
			dropdownItem.setAttribute('role', 'menuitem');
			dropdownItem.textContent = catValue.text;
			dropdownLi.append(dropdownItem);
			this.dropdown.append(dropdownLi);
		}

		// Insert text at a the current cursor position in a text input replacing the current selection if any.
		insertAtCursor(input, myValue) {
			if (!input) return;
			if (input.selectionStart || input.selectionStart == '0') {
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
			this.setSelection?.();
		}

		// Set the position of a cursor in a text input.
		setCursorPosition(input, pos) {
			if (!input) return;
			input.focus();
			input.setSelectionRange(pos, pos);
		}
	}

	// Hide any visible popovers when the escape key is pressed.
	document.addEventListener('keydown', (e) => {
		if (e.key === 'Escape') {
			for (const mviewerBtn of document.querySelectorAll('.codeshard-btn')) {
				bootstrap.Popover.getInstance(mviewerBtn)?.hide();
			}
		}
	});

	// Attach a viewer to each answer input
	for (const input of document.querySelectorAll('.codeshard')) {
		new MathViewer(input);
	}

	// Attach an editor to any needed latex/pg fields.
	for (const input of document.querySelectorAll('.latexentryfield')) {
		new MathViewer(input, { renderingMode: 'LATEX', decoratedTextBoxAsInput: false, includeDelimiters: true });
	}

	// Observer that sets up math viewers for inputs added to the page after initial page load.
	const observer = new MutationObserver((mutationsList) => {
		for (const mutation of mutationsList) {
			for (const node of mutation.addedNodes) {
				if (node instanceof Element) {
					if (node.dataset.mvInitialized === 'true') continue;

					if (node.classList.contains('codeshard')) new MathViewer(node);
					else node.querySelectorAll('.codeshard').forEach((input) => new MathViewer(input));
					if (node.classList.contains('latexentryfield'))
						new MathViewer(node, {
							renderingMode: 'LATEX',
							decoratedTextBoxAsInput: false,
							includeDelimiters: true
						});
					else
						node.querySelectorAll('.latexentryfield').forEach(
							(input) =>
								new MathViewer(input, {
									renderingMode: 'LATEX',
									decoratedTextBoxAsInput: false,
									includeDelimiters: true
								})
						);
				}
			}
		}
	});
	observer.observe(document.body, { childList: true, subtree: true });

	// Stop the mutation observer when the window is closed.
	window.addEventListener('unload', () => observer.disconnect());
})();
