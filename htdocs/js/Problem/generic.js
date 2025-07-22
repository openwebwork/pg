(() => {
	// Details accordions

	const setupAccordion = (accordion) => {
		const collapseEl = accordion.querySelector('.collapse');
		const button = accordion.querySelector('summary.accordion-button');
		const details = accordion.querySelector('details.accordion-item');
		if (!collapseEl || !button || !details) return;

		const collapse = new bootstrap.Collapse(collapseEl, { toggle: false });
		button.addEventListener('click', (e) => {
			collapse.toggle();
			e.preventDefault();
		});

		collapseEl.addEventListener('show.bs.collapse', () => {
			details.open = true;
			button.classList.remove('collapsed');
		});
		collapseEl.addEventListener('hide.bs.collapse', () => button.classList.add('collapsed'));
		collapseEl.addEventListener('hidden.bs.collapse', () => (details.open = false));
	};

	// Deal with solution/hint details that are already on the page.
	document.querySelectorAll('.solution.accordion, .hint.accordion').forEach(setupAccordion);

	// Deal with solution/hint details that are added to the page later.
	const observer = new MutationObserver((mutationsList) => {
		mutationsList.forEach((mutation) => {
			mutation.addedNodes.forEach((node) => {
				if (node instanceof Element) {
					if (
						(node.classList.contains('solution') || node.classList.contains('hint')) &&
						node.classList.contains('accordion')
					)
						setupAccordion(node);
					else node.querySelectorAll('.solution.accordion, .hint.accordion').forEach(setupAccordion);
				}
			});
		});
	});
	observer.observe(document.body, { childList: true, subtree: true });

	// Image long descriptions

	for (const dismissButton of document.querySelectorAll('.image-details-dismiss')) {
		dismissButton.addEventListener('click', () =>
			dismissButton.parentElement?.parentElement?.parentElement?.removeAttribute('open')
		);
	}

	for (const imageDescription of document.querySelectorAll('.image-details')) {
		const escapeCloseDetails = (e) => {
			if (e.key === 'Escape') imageDescription.removeAttribute('open');
		};
		const clickCloseDetails = (e) => {
			if (e.target.closest('.image-details') !== imageDescription) imageDescription.removeAttribute('open');
		};
		imageDescription.addEventListener('toggle', () => {
			if (imageDescription.open) {
				document.addEventListener('keydown', escapeCloseDetails);
				document.addEventListener('pointerdown', clickCloseDetails);
			} else {
				document.removeEventListener('keydown', escapeCloseDetails);
				document.removeEventListener('pointerdown', clickCloseDetails);
			}
		});
	}
})();
