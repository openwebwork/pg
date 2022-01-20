// For coloring the input elements with the proper color based on whether they are correct or incorrect.

(() => {
	const setupAnswerLink = (answerLink) => {
		const answerId = answerLink.dataset.answerId;
		const answerInput = document.getElementById(answerId);

		const type = answerLink.parentNode.classList.contains('ResultsWithoutError') ? 'correct' : 'incorrect';
		document.querySelectorAll(`input[name*=${answerId}],select[name*=${answerId}`)
			.forEach((input) => input.classList.add(type));

		if (answerInput) {
			answerLink.addEventListener('click', (e) => {
				e.preventDefault();
				answerInput.focus();
			});
		} else {
			answerLink.href = '';
		}
	};

	// Color inputs already on the page.
	document.querySelectorAll('td a[data-answer-id]').forEach(setupAnswerLink);

	// Deal with inputs that are added to the page later.
	const observer = new MutationObserver((mutationsList) => {
		mutationsList.forEach((mutation) => {
			mutation.addedNodes.forEach((node) => {
				if (node instanceof Element) {
					if (node.type && node.type.toLowerCase() === 'td' && node.firstElementChild
						&& node.firstElementChild.type.toLowerCase() == 'a' && node.firstElementChild.dataset.answerId)
						setupAnswerLink(node.firstElementChild);
					else node.querySelectorAll('td a[data-answer-id]').forEach(setupAnswerLink);
				}
			});
		});
	});
	observer.observe(document.body, { childList: true, subtree: true });

	// Stop the mutation observer when the window is closed.
	window.addEventListener('unload', () => observer.disconnect());
})();
