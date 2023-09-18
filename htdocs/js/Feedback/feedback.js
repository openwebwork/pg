(() => {
	const initializeFeedback = (feedbackBtn) => {
		if (feedbackBtn.dataset.popoverInitialized) return;
		feedbackBtn.dataset.popoverInitialized = 'true';

		new bootstrap.Popover(feedbackBtn, { sanitize: false });

		// Render MathJax previews.
		if (window.MathJax) {
			feedbackBtn.addEventListener('show.bs.popover', () => {
				MathJax.startup.promise = MathJax.startup.promise.then(() => MathJax.typesetPromise(['.popover-body']));
			});
		}

		// Execute javascript in the answer preview.
		feedbackBtn.addEventListener('shown.bs.popover', () => {
			const bsPopover = bootstrap.Popover.getInstance(feedbackBtn);
			bsPopover.tip?.querySelectorAll('script').forEach((origScript) => {
				const newScript = document.createElement('script');
				Array.from(origScript.attributes).forEach((attr) => newScript.setAttribute(attr.name, attr.value));
				newScript.appendChild(document.createTextNode(origScript.innerHTML));
				origScript.parentNode.replaceChild(newScript, origScript);
			});
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
