// ################################################################################
// # WeBWorK Online Homework Delivery System
// # Copyright &copy; 2000-2023 The WeBWorK Project, https://github.com/openwebwork
// #
// # This program is free software; you can redistribute it and/or modify it under
// # the terms of either: (a) the GNU General Public License as published by the
// # Free Software Foundation; either version 2, or (at your option) any later
// # version, or (b) the "Artistic License" which comes with this package.
// #
// # This program is distributed in the hope that it will be useful, but WITHOUT
// # ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
// # FOR A PARTICULAR PURPOSE.  See either the GNU General Public License or the
// # Artistic License for more details.
// ################################################################################
'use strict';

(() => {
	// Set up the radio-content divs corresponding to radio multi answer radios.
	const setupRadioContent = (radioContent) => {
		// Get all of the radios in the radio multianswer group.
		const rmaRadios = Array.from(
			document.querySelectorAll(`input[type="radio"][name="${radioContent.dataset.radio}"]`)
		);

		// Find the particular radio for this content.
		const contentRadio = rmaRadios.find((radio) => radio.value === radioContent.dataset.index);

		radioContent.addEventListener('click', () => {
			if (contentRadio.checked) return;
			contentRadio.checked = true;
			contentRadio.dispatchEvent(new Event('change'));
		});

		const answerRules = JSON.parse(radioContent.dataset.partNames);
		for (const answerRule of answerRules) {
			const input = document.getElementById(answerRule);

			// Collect all inputs for this answer.  The first is the visible answer rule.
			// If MathQuill is enabled, then this will be the MathQuill input.
			const answerInputs = [document.getElementById(`mq-answer-${answerRule}`) ?? input];

			// If this is a radio or checkbox answer, then save the other radio or checkbox inputs so they can be also
			// be disabled/enabled appropriately depending on which radio input in the radio multianswer group is
			// selected.
			const type = input.type?.toLowerCase();
			if (type && (type === 'radio' || type === 'checkbox')) {
				answerInputs.push(
					...Array.from(document.querySelectorAll(`input[type="${type}"][name="${answerRule}"]`)).filter(
						(input) => input.id !== answerRule
					)
				);
			}

			// Also get the hidden latex input if MathQuill is enabled so it can be disabled as needed.
			const mqLatexAns = document.getElementById(`MaThQuIlL_${answerRule}`);

			// Enable the inputs for this answer.
			const enableAnswer = () => {
				for (const input of answerInputs) {
					input.name = answerRule;
					input.classList.remove('rma-state-disabled');
				}
				if (mqLatexAns) mqLatexAns.disabled = false;
			};

			// Disable the inputs for this answer.  Removing the name attribute prevents the value from
			// being included with the submitted form.  This is better than disabling the input, as that
			// prevents events on the element.  The rma-state-disabled class gives it the appearance of
			// being disabled.
			const disableAnswer = () => {
				for (const input of answerInputs) {
					input.removeAttribute('name');
					input.classList.add('rma-state-disabled');
				}
				if (mqLatexAns) mqLatexAns.disabled = true;
			};

			for (const answerInput of answerInputs) {
				// Special case for selects.  If the select changes, then check the parent radio and enable its inputs.
				if (answerInput.tagName.toLowerCase() === 'select') {
					answerInput.addEventListener('change', () => {
						if (!contentRadio.checked) {
							contentRadio.checked = true;
							contentRadio.dispatchEvent(new Event('change'));
						}
					});
				}

				// If the user navigates to the input via the keyboard and starts to type, then check the parent radio
				// and enable its inputs.
				answerInput.addEventListener('keypress', (e) => {
					if (!contentRadio.checked) {
						// If enter was pressed, then prevent the form from being submitted.  At this point the
						// input was disabled, so give the user a chance to type something first.
						if (e.key === 'Enter') e.preventDefault();

						contentRadio.checked = true;
						contentRadio.dispatchEvent(new Event('change'));
						return;
					}
				});

				// Make sure the answer is enabled while it has focus.
				answerInput.addEventListener('focusin', enableAnswer);

				// If focus is lost and the parent radio is not checked, then disable the answer.
				answerInput.addEventListener('focusout', () => {
					if (contentRadio.checked) return;
					disableAnswer();
				});
			}

			// When a radio in the multianswer radio group changes, enable or disable the answer appropriately.
			for (const radio of rmaRadios) {
				radio.addEventListener('change', () => {
					if (contentRadio.checked) enableAnswer();
					else disableAnswer();
				});
				radio.dispatchEvent(new Event('change'));
			}
		}
	};

	// Setup uncheckable radios.
	const setupUncheckableRadio = (radio) => {
		if (!radio.dataset.uncheckableRadio) return;
		delete radio.dataset.uncheckableRadio;

		const firstRadio = document.getElementById(radio.name);
		if (radio.checked) firstRadio.dataset.currentChecked = radio.id;

		radio.addEventListener('click', (e) => {
			if (firstRadio.dataset.shift && !e.shiftKey) {
				firstRadio.dataset.currentChecked = radio.id;
				return;
			}
			const currentCheck = firstRadio.dataset.currentChecked;
			if (currentCheck && currentCheck === radio.id) {
				delete firstRadio.dataset.currentChecked;
				radio.checked = false;
				radio.dispatchEvent(new Event('change'));
			} else {
				firstRadio.dataset.currentChecked = radio.id;
			}
		});
	};

	// Deal with the radio-content divs already in the page.
	document.querySelectorAll('.radio-content').forEach(setupRadioContent);

	// Deal with uncheckable radios already in the page.
	document.querySelectorAll('input[type="radio"]').forEach(setupUncheckableRadio);

	// Deal with all radios that are added to the page later.
	const observer = new MutationObserver((mutationsList) => {
		for (const mutation of mutationsList) {
			for (const node of mutation.addedNodes) {
				if (node instanceof Element) {
					if (node.classList.contains('radio-content')) setupRadioContent(node);
					else node.querySelectorAll('.radio-content').forEach(setupRadioContent);

					if (node.tagName.toLowerCase() === 'input' && node.type.toLowerCase() === 'radio')
						setupUncheckableRadio(node);
					else node.querySelectorAll('input[type="radio"]').forEach(setupUncheckableRadio);
				}
			}
		}
	});
	observer.observe(document.body, { childList: true, subtree: true });

	// Stop the mutation observer when the window is closed.
	window.addEventListener('unload', () => observer.disconnect());
})();
