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

	// Stop the mutation observer when the window is closed.
	window.addEventListener('unload', () => observer.disconnect());
})();
