'use strict';

(() => {
	const addPreviewButton = (latexEntry) => {
		if (latexEntry.dataset.previewBtnAdded) return;
		latexEntry.dataset.previewBtnAdded = 'true';

		const buttonContainer = document.createElement('div');
		buttonContainer.classList.add('latexentry-button-container', 'mt-1');

		const button = document.createElement('button');
		button.type = 'button';
		button.classList.add('latexentry-preview', 'btn', 'btn-secondary', 'btn-sm');
		button.textContent = 'Preview';

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

		buttonContainer.append(button);
		latexEntry.after(buttonContainer);
	};

	document.querySelectorAll('.latexentryfield').forEach(addPreviewButton);

	const observer = new MutationObserver((mutationsList) => {
		for (const mutation of mutationsList) {
			for (const node of mutation.addedNodes) {
				if (node instanceof Element) {
					if (node.classList.contains('latexentryfield')) addPreviewButton(node);
					else node.querySelectorAll('.latexentryfield').forEach(addPreviewButton);
				}
			}
		}
	});
	observer.observe(document.body, { childList: true, subtree: true });

	window.addEventListener('unload', () => observer.disconnect());
})();
