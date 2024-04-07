(() => {
	const feedbackPopovers = [];

	const initializeFeedback = (feedbackBtn) => {
		if (feedbackBtn.dataset.popoverInitialized) return;
		feedbackBtn.dataset.popoverInitialized = 'true';

		const feedbackPopover = new bootstrap.Popover(feedbackBtn, {
			sanitize: false,
			container: feedbackBtn.parentElement
		});
		feedbackPopovers.push(feedbackPopover);

		// Render MathJax previews.
		if (window.MathJax) {
			feedbackBtn.addEventListener('show.bs.popover', () => {
				MathJax.startup.promise = MathJax.startup.promise.then(() => MathJax.typesetPromise(['.popover-body']));
			});
		}

		feedbackBtn.addEventListener('shown.bs.popover', () => {
			// Execute javascript in the answer preview.
			feedbackPopover.tip?.querySelectorAll('script').forEach((origScript) => {
				const newScript = document.createElement('script');
				Array.from(origScript.attributes).forEach((attr) => newScript.setAttribute(attr.name, attr.value));
				newScript.appendChild(document.createTextNode(origScript.innerHTML));
				origScript.parentNode.replaceChild(newScript, origScript);
				setTimeout(() => feedbackPopover.update());
			});

			const moveToFront = () => {
				if (feedbackPopover.tip) feedbackPopover.tip.style.zIndex = 18;
				for (const popover of feedbackPopovers) {
					if (popover === feedbackPopover) continue;
					popover.tip?.style.setProperty('z-index', null);
				}
			};
			feedbackPopover.tip?.addEventListener('click', moveToFront);
			feedbackPopover.tip?.addEventListener('focusin', moveToFront);
			moveToFront();

			// Make a click on the popover header close the popover.
			feedbackPopover.tip
				?.querySelector('.popover-header .btn-close')
				?.addEventListener('click', () => feedbackPopover.hide());

			if (feedbackPopover.tip) feedbackPopover.tip.dataset.iframeHeight = '1';

			const revealCorrectBtn = feedbackPopover.tip?.querySelector('.reveal-correct-btn');
			if (revealCorrectBtn && feedbackPopover.correctRevealed) {
				revealCorrectBtn.nextElementSibling?.classList.remove('d-none');
				revealCorrectBtn.remove();
			} else {
				revealCorrectBtn?.addEventListener('click', () => {
					feedbackPopover.correctRevealed = true;
					revealCorrectBtn.classList.add('fade-out');
					revealCorrectBtn.parentElement.classList.add('resize-transition');
					revealCorrectBtn.parentElement.style.maxWidth = `${revealCorrectBtn.parentElement.offsetWidth}px`;
					revealCorrectBtn.parentElement.style.maxHeight = `${revealCorrectBtn.parentElement.offsetHeight}px`;
					revealCorrectBtn.addEventListener('animationend', () => {
						revealCorrectBtn.nextElementSibling?.classList.remove('d-none');
						revealCorrectBtn.nextElementSibling?.classList.add('fade-in');
						revealCorrectBtn.parentElement.style.maxWidth = '1000px';
						revealCorrectBtn.parentElement.style.maxHeight = '1000px';
						revealCorrectBtn.remove();
						feedbackPopover.update();
					});
				});
			}
		});
	};

	// Setup feedback popovers already on the page.
	document.querySelectorAll('.ww-feedback-btn').forEach(initializeFeedback);

	// Deal with feedback popovers that are added to the page later.
	const observer = new MutationObserver((mutationsList) => {
		mutationsList.forEach((mutation) => {
			mutation.addedNodes.forEach((node) => {
				if (node instanceof Element) {
					if (node.classList.contains('ww-feedback-btn')) initializeFeedback(node.firstElementChild);
					else node.querySelectorAll('.ww-feedback-btn').forEach(initializeFeedback);
				}
			});
		});
	});
	observer.observe(document.body, { childList: true, subtree: true });

	// Stop the mutation observer when the window is closed.
	window.addEventListener('unload', () => observer.disconnect());
})();
