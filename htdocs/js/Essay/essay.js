'use strict';

(() => {
	const initializePreviewButton = (latexEntry) => {
		if (latexEntry.dataset.previewBtnInitialized) return;
		latexEntry.dataset.previewBtnInitialized = 'true';

		const buttonContainer =
			document.getElementById(`${latexEntry.id}-latexentry-button-container`) || document.createElement('div');

		if (!buttonContainer.classList.contains('latexentry-button-container')) {
			buttonContainer.classList.add('latexentry-button-container', 'mt-1');
			buttonContainer.id = `${latexEntry.id}-latexentry-button-container`;
			latexEntry.after(buttonContainer);
		}

		const button = buttonContainer.querySelector('.latexentry-preview') || document.createElement('button');

		if (!button.classList.contains('latexentry-preview')) {
			button.type = 'button';
			button.classList.add('latexentry-preview', 'btn', 'btn-secondary', 'btn-sm');
			button.textContent = 'Preview';

			buttonContainer.append(button);
		}

		button.addEventListener('click', () => {
			button.dataset.bsContent = latexEntry.value
				.replace(/</g, '< ')
				.replace(/>/g, ' >')
				.replace(/&/g, '&amp;')
				.replace(/\n/g, '<br>');
			if (button.dataset.bsContent) {
				if (button.dataset.popoverShown) button.dispatchEvent(new Event('hidden.bs.popover'));
				button.dataset.popoverShown = 'true';
				const popover = new bootstrap.Popover(button, {
					html: true,
					trigger: 'focus',
					placement: 'bottom',
					delay: { show: 0, hide: 200 }
				});
				button.addEventListener(
					'hidden.bs.popover',
					() => {
						delete button.dataset.popoverShown;
						popover.dispose();
					},
					{ once: true }
				);
				if (window.MathJax) {
					button.addEventListener(
						'show.bs.popover',
						() => {
							MathJax.startup.promise =
								MathJax.startup.promise.then(() => MathJax.typesetPromise(['.popover-body']));
						},
						{ once: true }
					);
				}
				popover.show();
			}
		});
	};

	document.querySelectorAll('.latexentryfield').forEach(initializePreviewButton);

	const observer = new MutationObserver((mutationsList) => {
		for (const mutation of mutationsList) {
			for (const node of mutation.addedNodes) {
				if (node instanceof Element) {
					if (node.classList.contains('latexentryfield')) initializePreviewButton(node);
					else node.querySelectorAll('.latexentryfield').forEach(initializePreviewButton);
				}
			}
		}
	});
	observer.observe(document.body, { childList: true, subtree: true });

	window.addEventListener('unload', () => observer.disconnect());
})();
