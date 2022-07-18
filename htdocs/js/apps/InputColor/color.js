// For coloring the input elements with the proper color based on whether they are correct or incorrect.

(() => {
	const setupAnswerLink = (answerLink) => {
		const answerId = answerLink.dataset.answerId;
		const answerInput = document.getElementById(answerId);

		const type = answerLink.parentNode.classList.contains('ResultsWithoutError') ? 'correct' : 'incorrect';
		const radioGroups = {};

		// Color all of the inputs and selects associated with this answer.  On the first pass radio inputs are
		// collected into groups by name, and on the second pass the checked radio is highlighted, or if none are
		// checked all are highlighted.
		document.querySelectorAll(`input[name*=${answerId}],select[name*=${answerId}`)
			.forEach((input) => {
				if (input.type.toLowerCase() === 'radio') {
					if (!radioGroups[input.name]) radioGroups[input.name] = [];
					radioGroups[input.name].push(input);
				} else {
					input.classList.add(type);
				}
			});

		Object.values(radioGroups).forEach((group) => {
			if (group.every((radio) => {
				if (radio.checked) {
					radio.classList.add(type);
					return false;
				}
				return true;
			})) {
				group.forEach((radio) => radio.classList.add(type));
			}
		});

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
