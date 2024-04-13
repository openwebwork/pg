/* global MathJax, Base64 */

(() => {
	let knowlUID = 0;

	// This sets the innerHTML of the element and executes any script tags therein.
	const setInnerHTML = (elt, html) => {
		elt.innerHTML = html;
		elt.querySelectorAll('script').forEach((origScript) => {
			const newScript = document.createElement('script');
			Array.from(origScript.attributes).forEach((attr) => newScript.setAttribute(attr.name, attr.value));
			newScript.appendChild(document.createTextNode(origScript.innerHTML));
			origScript.parentNode.replaceChild(newScript, origScript);
		});
	};

	const initializeKnowl = (knowl) => {
		knowl.dataset.bsToggle = 'modal';
		if (!knowl.knowlModal) {
			knowl.knowlModal = document.createElement('div');
			knowl.knowlModal.id = `knowl-uid-${knowlUID++}`;
			knowl.knowlModal.classList.add('modal', 'fade');
			knowl.knowlModal.tabIndex = -1;
			knowl.knowlModal.setAttribute('aria-labelledby', `${knowl.knowlModal.id}-title`);
			knowl.knowlModal.setAttribute('aria-hidden', 'true');

			const knowlDialog = document.createElement('div');
			knowlDialog.classList.add(
				'knowl-dialog',
				'modal-dialog',
				'modal-dialog-centered',
				'modal-dialog-scrollable'
			);
			knowlDialog.dataset.iframeHeight = '1';
			knowl.knowlModal.append(knowlDialog);

			const knowlContent = document.createElement('div');
			knowlContent.classList.add('modal-content');
			knowlDialog.append(knowlContent);

			const knowlHeader = document.createElement('div');
			knowlHeader.classList.add('modal-header');

			const knowlTitle = document.createElement('h1');
			knowlTitle.classList.add('modal-title', 'fs-5');
			knowlTitle.id = `${knowl.knowlModal.id}-title`;
			knowlTitle.textContent = knowl.dataset.knowlTitle || knowl.textContent;

			const closeButton = document.createElement('button');
			closeButton.type = 'button';
			closeButton.classList.add('btn-close');
			closeButton.dataset.bsDismiss = 'modal';
			closeButton.setAttribute('aria-label', 'Close');

			knowlHeader.append(knowlTitle, closeButton);

			const knowlBody = document.createElement('div');
			knowlBody.classList.add('modal-body');

			knowlContent.append(knowlHeader, knowlBody);

			if (knowl.dataset.knowlUrl) {
				const knowlFooter = document.createElement('div');
				knowlFooter.classList.add('modal-footer', 'knowl-footer', 'justify-content-center', 'p-1');
				knowlFooter.textContent = knowl.dataset.knowlUrl;
				knowlContent.append(knowlFooter);
			}

			knowl.knowlModal.addEventListener('shown.bs.modal', () => {
				const heightAdjust = Math.min(
					600,
					knowlBody.scrollHeight +
						knowlHeader.offsetHeight +
						(knowlContent.querySelector('.modal-footer')?.offsetHeight || 0)
				);
				if (knowlDialog.offsetHeight < heightAdjust) knowlDialog.style.height = `${heightAdjust}px`;
			});

			document.body.append(knowl.knowlModal);

			knowl.dataset.bsTarget = `#${knowl.knowlModal.id}`;

			if (knowl.dataset.knowlContents) {
				// Inline html
				setInnerHTML(knowlBody, knowl.dataset.knowlContents);

				// If we are using MathJax, then render math content.
				if (window.MathJax) {
					MathJax.startup.promise = MathJax.startup.promise.then(() => MathJax.typesetPromise([knowlBody]));
				}
			} else if (knowl.dataset.knowlUrl) {
				// Retrieve url content.
				fetch(knowl.dataset.knowlUrl)
					.then((response) => (response.ok ? response.text() : response))
					.then((data) => {
						if (typeof data == 'object') {
							knowlBody.textContent = `ERROR: ${data.status} ${data.statusText}`;
							knowlBody.classList.add('knowl-error');
						} else {
							setInnerHTML(knowlBody, data);
						}
						// If we are using MathJax, then render math content.
						if (window.MathJax) {
							MathJax.startup.promise = MathJax.startup.promise.then(() =>
								MathJax.typesetPromise([knowlBody])
							);
						}
					})
					.catch((err) => {
						knowlBody.textContent = `ERROR: ${err}`;
						knowlBody.classList.add('knowl-error');
					});
			} else {
				knowlBody.textContent = 'ERROR: knowl content not provided.';
				knowlBody.classList.add('knowl-error');
			}
		}
	};

	// Deal with knowls that are already on the page.
	document.querySelectorAll('.knowl').forEach(initializeKnowl);

	// Deal with knowls that are added to the page later.
	const observer = new MutationObserver((mutationsList) => {
		mutationsList.forEach((mutation) => {
			mutation.addedNodes.forEach((node) => {
				if (node instanceof Element) {
					if (node.classList.contains('knowl')) initializeKnowl(node);
					else node.querySelectorAll('.knowl').forEach(initializeKnowl);
				}
			});
		});
	});
	observer.observe(document.body, { childList: true, subtree: true });
})();
