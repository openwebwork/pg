'use strict';

(() => {
	const radioGroups = {};

	// Setup uncheckable radios.
	const setupUncheckableRadio = (radio) => {
		if (!radio.dataset.uncheckableRadioButton) return;
		delete radio.dataset.uncheckableRadioButton;

		if (!radioGroups[radio.name]) radioGroups[radio.name] = [radio];
		else radioGroups[radio.name].push(radio);

		if (radio.checked) radio.dataset.currentlyChecked = '1';

		radio.addEventListener('click', (e) => {
			for (const groupRadio of radioGroups[radio.name]) {
				if (groupRadio === radio) continue;
				delete groupRadio.dataset.currentlyChecked;
			}
			if (radio.dataset.shift && !e.shiftKey) {
				radio.dataset.currentlyChecked = '1';
				return;
			}
			if (radio.dataset.currentlyChecked) {
				delete radio.dataset.currentlyChecked;
				radio.checked = false;
			} else {
				radio.dataset.currentlyChecked = '1';
			}
		});
	};

	// Deal with uncheckable radios already in the page.
	document.querySelectorAll('input[type="radio"]').forEach(setupUncheckableRadio);

	// Deal with radios that are added to the page later.
	const observer = new MutationObserver((mutationsList) => {
		for (const mutation of mutationsList) {
			for (const node of mutation.addedNodes) {
				if (node instanceof Element) {
					if (node.tagName.toLowerCase() === 'input' && node.type.toLowerCase() === 'radio')
						setupUncheckableRadio(node);
					else node.querySelectorAll('input[type="radio"]').forEach(setupUncheckableRadio);
				}
			}
		}
	});
	observer.observe(document.body, { childList: true, subtree: true });
})();
