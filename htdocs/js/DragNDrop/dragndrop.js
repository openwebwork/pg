'use strict';

(() => {
	class BucketPool {
		constructor(el) {
			// Set a marker in the element dataset to prevent another BucketPool object from being created for it.
			el.dataset.bucketPoolInitialized = 'true';

			this.answerName = el.dataset.answerName ?? '';
			this.buckets = [];
			this.removeButtonText = el.dataset.removeButtonText ?? 'Remove';

			this.answerInput = el.parentElement.querySelector(`input[name="${this.answerName}"]`);
			if (!this.answerInput) {
				// This should not happen if using the macros.
				alert(`FATAL ERROR: Unable to find answer input corresponding to ${this.answerName}.`);
				return;
			}

			this.bucketContainer = document.createElement('div');
			this.bucketContainer.classList.add('dd-pool-bucket-container');
			el.prepend(this.bucketContainer);

			this.itemList = JSON.parse(el.dataset.itemList ?? '[]');
			this.defaultState = JSON.parse(el.dataset.defaultState ?? '[]');
			this.labelFormat = el.dataset.labelFormat;

			if (this.answerInput.value) {
				// Need to check for things like (3,2,1) for backwards compatibility.  Now it will be {3,2,1}.
				const matches = this.answerInput.value.match(/((?:\{|\()[^\{\}\(\)]*(?:\}|\)))/g);
				for (const match of matches) {
					const i = this.buckets.length;
					const bucket = {
						removable: i < this.defaultState.length ? this.defaultState[i].removable : 1,
						label: i < this.defaultState.length ? this.defaultState[i].label : '',
						indices: match
							.replaceAll(/\{|\}|\(|\)/g, '')
							.split(',')
							.filter((index) => index !== '')
					};
					this.buckets.push(new Bucket(this, i, bucket));
				}
			} else {
				for (const bucket of this.defaultState) {
					this.buckets.push(new Bucket(this, this.buckets.length, bucket));
				}
			}
			this.updateAnswerInput();

			el.querySelector('.dd-add-bucket')?.addEventListener('click', () => {
				// When buckets are removed and added the id's may not be sequential anymore.  So the bucket count
				// cannot directly be used, and an id needs to be found that is not already in use.
				let id = 0;
				for (const bucketId of this.buckets.map((b) => b.id).sort()) {
					if (id != bucketId) break;
					++id;
				}

				this.buckets.push(new Bucket(this, id, { removable: 1 }));
				this.updateAnswerInput();
			});

			el.querySelector('.dd-reset-buckets')?.addEventListener('click', () => {
				for (const bucket of this.buckets) {
					bucket.el.remove();
				}
				this.buckets = [];

				for (const bucket of this.defaultState) {
					this.buckets.push(new Bucket(this, this.buckets.length, bucket));
				}
				this.updateAnswerInput();
			});
		}

		updateAnswerInput() {
			const contents = [];

			for (const bucket of this.buckets) {
				const list = bucket.sortable.toArray();
				contents.push(`{${list.join(',')}}`);
			}

			this.answerInput.value = '(' + contents.join(',') + ')';
		}
	}

	class Bucket {
		constructor(bucketPool, id, bucketData) {
			this.id = id;
			this.bucketPool = bucketPool;

			this.el = this.htmlBucket(bucketData.label, bucketData.removable, bucketData.indices);
			bucketPool.bucketContainer.append(this.el);

			// Typeset any math content that may be in the added html.
			if (window.MathJax) {
				MathJax.startup.promise = MathJax.startup.promise.then(() => MathJax.typesetPromise([this.el]));
			}

			this.sortable = Sortable.create(this.ddList, {
				group: bucketPool.answerName,
				animation: 150,
				onEnd: () => this.bucketPool.updateAnswerInput()
			});
		}

		htmlBucket(label, removable, indices = []) {
			const bucketElement = document.createElement('div');
			bucketElement.classList.add('dd-bucket');

			const bucketLabel = document.createElement('div');
			bucketLabel.classList.add('dd-bucket-label');
			bucketLabel.innerHTML =
				label || (this.bucketPool.labelFormat ? `${this.bucketPool.labelFormat.replace(/%s/, this.id + 1)}` : '');

			this.ddList = document.createElement('div');
			this.ddList.classList.add('dd-list');

			bucketElement.append(bucketLabel, this.ddList);

			for (const index of indices) {
				if (index < 0 || index > this.bucketPool.itemList.length) continue;

				const listElement = document.createElement('div');
				listElement.classList.add('dd-item');
				listElement.dataset.id = index;
				listElement.innerHTML = this.bucketPool.itemList[index];

				this.ddList.append(listElement);
			}

			bucketElement.style.backgroundColor = `hsla(${(100 + this.id * 100) % 360}, 40%, 90%, 1)`;

			// The first bucket is not allowed to be removable.
			if (this.id !== 0 && removable) {
				const removeButton = document.createElement('button');
				removeButton.type = 'button';
				removeButton.classList.add('btn', 'btn-secondary', 'dd-remove-bucket-button');
				removeButton.textContent = this.bucketPool.removeButtonText;

				removeButton.addEventListener('click', () => {
					const firstBucketList = this.bucketPool.buckets[0].ddList;
					for (const item of this.ddList.querySelectorAll('.dd-item')) {
						firstBucketList.append(item);
					}

					bucketElement.remove();
					const index = this.bucketPool.buckets.findIndex((bucket) => bucket.id === this.id);
					if (index !== -1) this.bucketPool.buckets.splice(index, 1);
					this.bucketPool.updateAnswerInput();
				});

				bucketElement.append(removeButton);
			}

			return bucketElement;
		}
	}

	// Set up bucket pools that are already in the page.
	for (const bucketPoolEl of document.querySelectorAll('.dd-bucket-pool')) {
		new BucketPool(bucketPoolEl);
	}

	// Set up bucket pools that are added to the page later.
	const observer = new MutationObserver((mutationsList) => {
		for (const mutation of mutationsList) {
			for (const node of mutation.addedNodes) {
				if (node instanceof Element) {
					if (node.classList.contains('dd-bucket-pool')) {
						if (!node.dataset.bucketPoolInitialized) new BucketPool(node);
					} else {
						for (const bucketPoolEl of node.querySelectorAll('.dd-bucket-pool')) {
							if (bucketPoolEl.dataset.bucketPoolInitialized) continue;
							new BucketPool(bucketPoolEl);
						}
					}
				}
			}
		}
	});
	observer.observe(document.body, { childList: true, subtree: true });

	// Stop the mutation observer when the window is closed.
	window.addEventListener('unload', () => observer.disconnect());
})();
