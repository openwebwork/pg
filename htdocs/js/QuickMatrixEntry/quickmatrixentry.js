/* global bootstrap */

'use strict';

(() => {
	const setupQuickMatrixEntryBtn = (button) => {
		button.addEventListener('click', () => {
			const name = button.name;

			const modal = document.createElement('div');
			modal.classList.add('modal');
			modal.tabIndex = -1;
			modal.setAttribute('aria-labelledby', 'matrix-entry-dialog-title');
			modal.setAttribute('aria-hidden', 'true');

			const modalDialog = document.createElement('div');
			modalDialog.classList.add('modal-dialog', 'modal-dialog-centered');
			const modalContent = document.createElement('div');
			modalContent.classList.add('modal-content');

			const modalHeader = document.createElement('div');
			modalHeader.classList.add('modal-header');

			const title = document.createElement('h1');
			title.classList.add('fs-3', 'm-0');
			title.id = 'matrix-entry-dialog-title';
			title.textContent = 'Enter matrix';

			const closeButton = document.createElement('button');
			closeButton.type = 'button';
			closeButton.classList.add('btn-close');
			closeButton.dataset.bsDismiss = 'modal';
			closeButton.setAttribute('aria-label', 'close');

			modalHeader.append(title, closeButton);

			const modalBody = document.createElement('div');
			modalBody.classList.add('modal-body');
			const modalBodyContent = document.createElement('div');
			modalBody.append(modalBodyContent);

			const textarea = document.createElement('textarea');
			textarea.classList.add('form-control');
			textarea.rows = 10;
			modalBodyContent.append(textarea);

			const modalFooter = document.createElement('div');
			modalFooter.classList.add('modal-footer');

			const enterButton = document.createElement('button');
			enterButton.classList.add('btn', 'btn-primary');
			enterButton.textContent = 'Enter';

			modalFooter.append(enterButton);
			modalContent.append(modalHeader, modalBody, modalFooter);
			modalDialog.append(modalContent);
			modal.append(modalDialog);

			const insert_value = (i, j, entry) => {
				const input = document.getElementById(i == 0 && j == 0 ? name : `MaTrIx_${name}_${i}_${j}`);
				if (!input) return;
				input.value = entry;
				if (window.answerQuills && window.answerQuills[input.name])
					answerQuills[input.name].mathField.latex(entry);
			};

			const extract_value = (i, j) =>
				document.getElementById(i == 0 && j == 0 ? name : `MaTrIx_${name}_${i}_${j}`)?.value || 0;

			const rows = parseInt(button.dataset.rows);
			const columns = parseInt(button.dataset.columns);

			// Enter something that indicates how many columns to fill.
			const entries = [];
			for (let i = 0; i < rows; ++i) {
				entries.push([]);
				for (let j = 0; j < columns; ++j) {
					entries[entries.length - 1].push(extract_value(i, j));
				}
			}
			textarea.value = entries.map((row) => row.join(' ')).join('\n');

			enterButton.addEventListener('click', () => {
				// Get the textarea value, and then remove initial and trailing white space, replace commas with a
				// space, replace end brackets with a new line, and remove start brackets. Then split on new lines.
				const matrix = [];
				for (const row of textarea.value
					.replace(/^\s*|\s*$/, '')
					.replace(/,/g, ' ')
					.replace(/\]/g, '\n')
					.replace(/\[/g, '')
					.split(/\n/)) {
					matrix.push(row.replace(/^\s*/, '').split(/\s+/));
				}

				for (let i = 0; i < matrix.length; ++i) {
					for (let j = 0; j < matrix[i].length; ++j) {
						insert_value(i, j, matrix[i][j]);
					}
				}

				bsModal.hide();
			});

			const bsModal = new bootstrap.Modal(modal);
			bsModal.show();
			document.querySelector('.modal-backdrop')?.style.setProperty('--bs-backdrop-opacity', '0.2');

			modal.addEventListener('hidden.bs.modal', () => {
				bsModal.dispose();
				modal.remove();
			});
		});
	};

	// Deal with uncheckable radios already in the page.
	document.querySelectorAll('.quick-matrix-entry-btn').forEach(setupQuickMatrixEntryBtn);

	// Deal with radios that are added to the page later.
	const observer = new MutationObserver((mutationsList) => {
		for (const mutation of mutationsList) {
			for (const node of mutation.addedNodes) {
				if (node instanceof Element) {
					if (node.classList.contains('quick-matrix-entry-btn')) setupQuickMatrixEntryBtn(node);
					else node.querySelectorAll('.quick-matrix-entry-btn').forEach(setupQuickMatrixEntryBtn);
				}
			}
		}
	});
	observer.observe(document.body, { childList: true, subtree: true });
	window.addEventListener('unload', () => observer.disconnect());
})();
