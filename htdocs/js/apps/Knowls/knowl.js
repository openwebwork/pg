/* global MathJax, Base64 */

(() => {
	let knowlUID = 0;

	// This sets the innerHTML of the element and executes any script tags therein.
	const setInnerHTML = (elt, html) => {
		elt.innerHTML = html;
		elt.querySelectorAll('script').forEach((origScript) => {
			const newScript = document.createElement('script');
			Array.from(origScript.attributes).forEach(attr => newScript.setAttribute(attr.name, attr.value));
			newScript.appendChild(document.createTextNode(origScript.innerHTML));
			origScript.parentNode.replaceChild(newScript, origScript);
		});
	};

	const initializeKnowl = (knowl) => {
		knowl.dataset.bsToggle = 'collapse';
		if (!knowl.knowlContainer) {
			knowl.knowlContainer = document.createElement('div');
			knowl.knowlContainer.id = `knowl-uid-${knowlUID++}`;
			knowl.knowlContainer.classList.add('collapse');

			const knowlOutput = document.createElement('div');
			knowlOutput.classList.add('knowl-output');

			const knowlContent = document.createElement('div');
			knowlContent.classList.add('knowl-content');
			knowlOutput.append(knowlContent);

			if (knowl.dataset.knowlUrl) {
				const knowlFooter = document.createElement('div');
				knowlFooter.classList.add('knowl-footer');
				knowlFooter.textContent = knowl.dataset.knowlUrl;
				knowlOutput.append(knowlFooter);
			}

			knowl.knowlContainer.appendChild(knowlOutput);

			knowl.knowlContainer.addEventListener('show.bs.collapse', () => knowl.classList.add('active'));
			knowl.knowlContainer.addEventListener('hide.bs.collapse', () => knowl.classList.remove('active'));

			// If the knowl is inside a table row, then insert a new row into the table after that one to contain
			// the knowl content.  If the knowl is inside a list element, then insert the content after the list
			// element.  Otherwise insert the content either before the first sibling that follows it that is
			// display block, or append it to the first ancestor that is display block.
			let insertElt = knowl.closest('tr');
			if (insertElt) {
				const row = document.createElement('tr');
				const td = document.createElement('td');
				td.colSpan = insertElt.childElementCount;
				td.appendChild(knowl.knowlContainer);
				row.appendChild(td);
				insertElt.after(row);
			} else {
				insertElt = knowl.closest('li');
				if (insertElt) {
					insertElt.after(knowl.knowlContainer);
				} else {
					let append = false;
					insertElt = knowl;
					do {
						const lastElt = insertElt;
						insertElt = lastElt.nextElementSibling;
						if (!insertElt) {
							insertElt = lastElt.parentNode;
							append = true;
						}
					} while (getComputedStyle(insertElt)?.getPropertyValue('display') !== 'block');

					if (append) insertElt.append(knowl.knowlContainer);
					else insertElt.before(knowl.knowlContainer);
				}
			}

			knowl.dataset.bsTarget = `#${knowl.knowlContainer.id}`;

			if (knowl.dataset.knowlContents) {
				// Inline html
				if (knowl.dataset.base64 == '1') {
					if (window.Base64)
						setInnerHTML(knowlContent, Base64.decode(knowl.dataset.knowlContents));
					else {
						setInnerHTML(knowlContent, 'ERROR: Base64 decoding not available');
						knowlContent.classList.add('knowl-error');
					}
				} else {
					setInnerHTML(knowlContent, knowl.dataset.knowlContents);
				}
				// If we are using MathJax, then render math content.
				if (window.MathJax) {
					MathJax.startup.promise =
						MathJax.startup.promise.then(() => MathJax.typesetPromise([knowlContent]));
				}
			} else if (knowl.dataset.knowlUrl) {
				// Retrieve url content.
				fetch(knowl.dataset.knowlUrl).then((response) => response.ok ? response.text() : response)
					.then((data) => {
						if (typeof data == 'object') {
							knowlContent.textContent = `ERROR: ${data.status} ${data.statusText}`;
							knowlContent.classList.add('knowl-error');
						} else {
							setInnerHTML(knowlContent, data);
						}
						// If we are using MathJax, then render math content.
						if (window.MathJax) {
							MathJax.startup.promise =
								MathJax.startup.promise.then(() => MathJax.typesetPromise([knowlContent]));
						}
					});
			} else {
				knowlContent.textContent = 'ERROR: knowl content not provided.';
				knowlContent.classList.add('knowl-error');
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
