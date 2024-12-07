(() => {
	const setupDropdown = (dropdown) => {
		const input = dropdown?.querySelector(`input[name="${dropdown.dataset.feedbackInsertElement}"]`);
		const dropdownBtn = dropdown?.querySelector('button.dropdown-toggle');
		if (!dropdown || !input || !dropdownBtn) return;

		// Give the dropdown button the correct/incorrect colors.
		if (input.classList.contains('correct')) dropdownBtn.classList.add('correct');
		if (input.classList.contains('incorrect')) dropdownBtn.classList.add('incorrect');
		if (input.classList.contains('partially-correct')) dropdownBtn.classList.add('partially-correct');

		const options = Array.from(dropdown.querySelectorAll('.dropdown-item:not(.disabled)'));

		dropdown.addEventListener('shown.bs.dropdown', () => {
			for (const option of options) {
				if (option.classList.contains('active')) {
					option.focus();
					break;
				}
			}
		});

		for (const option of options) {
			option.addEventListener('click', () => {
				options.forEach((o) => o.classList.remove('active'));
				option.classList.add('active');
				input.value = option.dataset.value;
				dropdownBtn.textContent = option.dataset.content;
				dropdownBtn.focus();

				if (window.MathJax)
					MathJax.startup.promise = MathJax.startup.promise.then(() => MathJax.typesetPromise([dropdownBtn]));

				// If any feedback popovers are open, then update their positions.
				for (const popover of document.querySelectorAll('.ww-feedback-btn')) {
					bootstrap.Popover.getInstance(popover)?.update();
				}
			});
		}
	};

	// Set up dropdowns that are already in the page.
	document.querySelectorAll('.pg-dropdown').forEach(setupDropdown);

	// Observer that sets up MathQuill inputs.
	const observer = new MutationObserver((mutationsList) => {
		for (const mutation of mutationsList) {
			for (const node of mutation.addedNodes) {
				if (node instanceof Element) {
					if (node.classList.contains('pg-dropdown')) {
						setupDropdown(node);
					} else {
						node.querySelectorAll('.pg-dropdown').forEach(setupDropdown);
					}
				}
			}
		}
	});
	observer.observe(document.body, { childList: true, subtree: true });

	// Stop the mutation observer when the window is closed.
	window.addEventListener('unload', () => observer.disconnect());
})();
