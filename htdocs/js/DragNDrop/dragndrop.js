'use strict';

(() => {
	class BucketPool {
		constructor(el) {
			// Set a marker in the element dataset to prevent another BucketPool object from being created for it.
			el.dataset.bucketPoolInitialized = 'true';

			this.answerName = el.dataset.answerName ?? '';
			this.buckets = [];

			this.answerInput = el.parentElement?.querySelector(`input[name="${this.answerName}"]`);
			if (!this.answerInput) {
				// This should not happen if using the macros.
				alert(`FATAL ERROR: Unable to find answer input corresponding to ${this.answerName}.`);
				return;
			}

			el.role = 'application';

			this.itemList = JSON.parse(el.dataset.itemList ?? '[]');
			this.defaultState = JSON.parse(el.dataset.defaultState ?? '[]');
			this.showUniversalSet = 'showUniversalSet' in el.dataset;

			// Translatable/customizable text.
			this.labelFormat = el.dataset.labelFormat;
			this.removeButtonText = el.dataset.removeButtonText ?? 'Remove';
			this.universalSetLabel = el.dataset.universalSetLabel ?? 'Universal Set';
			this.addFromUniversalText =
				el.dataset.addFromUniversalText ?? 'Item %1s in the universal set added as item %2s to list %3s.';
			this.removeUniversalItemText = el.dataset.removeUniversalItemText ?? 'Item %1s removed from list %2s.';
			this.reorderText = el.dataset.reorderText ?? 'Moved item %1s in list %2s to item %3s.';
			this.moveText = el.dataset.moveText ?? 'Moved item %1s in list %2s to item %3s in list %4s.';

			this.bucketContainer = document.createElement('div');
			this.bucketContainer.classList.add('dd-pool-bucket-container');
			el.prepend(this.bucketContainer);

			if (this.answerInput.value) {
				// Need to check for things like (3,2,1) for backwards compatibility.  Now it will be {3,2,1}.
				const matches = this.answerInput.value.match(/((?:\{|\()[^{}()]*(?:\}|\)))/g);
				for (const match of matches ?? []) {
					const i = this.buckets.length;
					const bucket = {
						removable: i < this.defaultState.length ? this.defaultState[i].removable : 1,
						label: i < this.defaultState.length ? this.defaultState[i].label : '',
						indices: match
							.replaceAll(/\{|\}|\(|\)/g, '')
							.split(',')
							.filter((index) => index !== '')
							.map((i) => parseInt(i))
					};
					this.buckets.push(new Bucket(this, i, bucket));
				}
			} else {
				for (const bucket of this.defaultState) {
					this.buckets.push(new Bucket(this, this.buckets.length, bucket));
				}
			}
			this.updateAnswerInput();

			if (this.showUniversalSet) {
				this.universalSetContainer = document.createElement('div');
				this.universalSetContainer.classList.add('dd-pool-bucket-container');
				el.prepend(this.universalSetContainer);

				this.universalSetBucket = new Bucket(this, this.buckets.length, {
					isUniversalSet: true,
					removable: false,
					label: this.universalSetLabel,
					indices: this.itemList.map((_el, i) => i)
				});
			}

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

				for (const bucket of this.defaultState ?? []) {
					this.buckets.push(new Bucket(this, this.buckets.length, bucket));
				}
				this.updateAnswerInput();
			});

			this.announcer = document.createElement('div');
			this.announcer.setAttribute('aria-live', 'assertive');
			this.announcer.className = 'visually-hidden';
			el.append(this.announcer);

			el.addEventListener('keydown', (e) => {
				if (
					!['ArrowUp', 'ArrowDown', 'ArrowLeft', 'ArrowRight'].includes(e.key) ||
					!e.target ||
					!(e.target instanceof HTMLElement)
				)
					return;
				const item = e.target.closest('.dd-item');
				if (!item || !(item instanceof HTMLElement)) return;

				if (this.universalSetBucket) {
					const children = this.universalSetBucket.items;
					const index = children.indexOf(item);
					if (index !== -1) {
						e.preventDefault();
						let toBucketIndex = 0;
						if (e.key === 'ArrowRight' || e.key === 'ArrowDown') {
							while (
								toBucketIndex < this.buckets.length &&
								this.buckets[toBucketIndex].hasItem(item.dataset.id)
							)
								++toBucketIndex;
						} else if (e.key === 'ArrowLeft' || e.key === 'ArrowUp') {
							toBucketIndex = this.buckets.length - 1;
							while (toBucketIndex >= 0 && this.buckets[toBucketIndex].hasItem(item.dataset.id))
								--toBucketIndex;
						}
						if (toBucketIndex >= 0 && toBucketIndex < this.buckets.length) {
							this.copyUniversalItem(item, this.buckets[toBucketIndex]);
							this.announce(
								this.addFromUniversalText,
								index + 1,
								this.buckets[toBucketIndex].items.length,
								toBucketIndex + 1
							);
						}
						this.updateAnswerInput();
						return;
					}
				}

				for (const [bucketIndex, bucket] of this.buckets.entries()) {
					const children = bucket.items;
					const index = children.indexOf(item);
					if (index === -1) continue;

					e.preventDefault();

					if (e.key === 'ArrowUp' && index > 0) {
						bucket.swapItems(item, children[index - 1]);
						this.announce(this.reorderText, index + 1, bucketIndex + 1, index);
					} else if (e.key === 'ArrowDown' && index < children.length - 1) {
						bucket.swapItems(item, children[index + 1]);
						this.announce(this.reorderText, index + 1, bucketIndex + 1, index + 2);
					} else if (
						e.key === 'ArrowLeft' &&
						(bucketIndex > 0 || (this.universalSetBucket && bucketIndex === 0))
					) {
						let toBucketIndex = bucketIndex - 1;
						if (this.universalSetBucket) {
							while (toBucketIndex >= 0 && this.buckets[toBucketIndex].hasItem(item.dataset.id))
								--toBucketIndex;
						}
						if (toBucketIndex >= 0) {
							this.moveItem(item, bucket, this.buckets[toBucketIndex]);
							this.announce(
								this.moveText,
								index + 1,
								bucketIndex + 1,
								this.buckets[toBucketIndex].items.length,
								toBucketIndex + 1
							);
						} else if (this.universalSetBucket) {
							bucket.removeItem(item);
							for (const universalItem of this.universalSetBucket.items) {
								if (universalItem.dataset.id === item.dataset.id) {
									universalItem.focus();
									break;
								}
							}
							this.announce(this.removeUniversalItemText, index + 1, bucketIndex + 1);
						}
					} else if (
						e.key === 'ArrowRight' &&
						(bucketIndex < this.buckets.length - 1 ||
							(this.universalSetBucket && bucketIndex === this.buckets.length - 1))
					) {
						let toBucketIndex = bucketIndex + 1;
						if (this.universalSetBucket) {
							while (
								toBucketIndex < this.buckets.length &&
								this.buckets[toBucketIndex].hasItem(item.dataset.id)
							)
								++toBucketIndex;
						}
						if (toBucketIndex < this.buckets.length) {
							this.moveItem(item, bucket, this.buckets[toBucketIndex]);
							this.announce(
								this.moveText,
								index + 1,
								bucketIndex + 1,
								this.buckets[toBucketIndex].items.length,
								toBucketIndex + 1
							);
						} else if (this.universalSetBucket) {
							bucket.removeItem(item);
							for (const universalItem of this.universalSetBucket.items) {
								if (universalItem.dataset.id === item.dataset.id) {
									universalItem.focus();
									break;
								}
							}
							this.announce(this.removeUniversalItemText, index + 1, bucketIndex + 1);
						}
					}
					this.updateAnswerInput();
					break;
				}
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

		announce(message, ...replacements) {
			let interpolatedMessage = message;
			for (const interpolation of message.matchAll(/(%(\d)s)/g)) {
				const position = parseInt(interpolation[2]) - 1;
				interpolatedMessage = interpolatedMessage.replace(interpolation[1], replacements[position]);
			}
			this.announcer.textContent = interpolatedMessage;
		}

		// Move a list item from one bucket to another and animate the changes to the DOM.
		moveItem(element, fromBucket, toBucket) {
			const siblings = fromBucket.items.filter((e) => e !== element);

			const fromBucketHeight = fromBucket.el.getBoundingClientRect().height;
			const toBucketHeight = toBucket.el.getBoundingClientRect().height;
			const elementRect = element.getBoundingClientRect();
			const siblingRects = siblings.map((e) => e.getBoundingClientRect());

			toBucket.ddList.append(element);
			element.focus();

			const newFromBucketHeight = fromBucket.el.getBoundingClientRect().height;
			const newToBucketHeight = toBucket.el.getBoundingClientRect().height;
			const newElementRect = element.getBoundingClientRect();
			const newSiblingRects = siblings.map((e) => e.getBoundingClientRect());

			requestAnimationFrame(() => {
				for (const [bucket, height, newHeight] of [
					[fromBucket, fromBucketHeight, newFromBucketHeight],
					[toBucket, toBucketHeight, newToBucketHeight]
				]) {
					bucket.el.animate([{ height: `${height}px` }, { height: `${newHeight}px` }], {
						duration: 150,
						easing: 'ease'
					});
				}

				element.style.position = 'fixed';
				element.style.top = `${newElementRect.top}px`;
				element.style.left = `${newElementRect.left}px`;
				element.style.width = `${newElementRect.width}px`;
				element.style.pointerEvents = 'none';

				element
					.animate(
						[
							{
								transformOrigin: 'top left',
								transform: `translate(${
									elementRect.left - newElementRect.left
								}px, ${elementRect.top - newElementRect.top}px)`
							},
							{ transformOrigin: 'top left', transform: 'none' }
						],
						{ duration: 150, easing: 'ease' }
					)
					.finished.then(() => {
						element.style.position = '';
						element.style.top = '';
						element.style.left = '';
						element.style.width = '';
						element.style.pointerEvents = '';
						element.focus();
					})
					.catch(() => {
						/* ignore */
					});

				for (const [index, sibling] of siblings.entries()) {
					sibling.animate(
						[
							{
								transformOrigin: 'top left',
								transform: `translate(${
									siblingRects[index].left - newSiblingRects[index].left
								}px, ${siblingRects[index].top - newSiblingRects[index].top}px)`
							},
							{ transformOrigin: 'top left', transform: 'none' }
						],
						{ duration: 150, easing: 'ease' }
					);
				}
			});
		}

		// Copy an item from the universal set bucket to another bucket and animate it moving there.
		copyUniversalItem(element, toBucket) {
			const toBucketHeight = toBucket.el.getBoundingClientRect().height;
			const elementRect = element.getBoundingClientRect();

			const elementCopy = element.cloneNode(true);
			toBucket.ddList.append(elementCopy);
			elementCopy.focus();

			const newToBucketHeight = toBucket.el.getBoundingClientRect().height;
			const newElementRect = elementCopy.getBoundingClientRect();

			requestAnimationFrame(() => {
				toBucket.el.animate([{ height: `${toBucketHeight}px` }, { height: `${newToBucketHeight}px` }], {
					duration: 150,
					easing: 'ease'
				});

				elementCopy.style.position = 'fixed';
				elementCopy.style.top = `${newElementRect.top}px`;
				elementCopy.style.left = `${newElementRect.left}px`;
				elementCopy.style.width = `${newElementRect.width}px`;
				elementCopy.style.pointerEvents = 'none';

				elementCopy
					.animate(
						[
							{
								transformOrigin: 'top left',
								transform: `translate(${
									elementRect.left - newElementRect.left
								}px, ${elementRect.top - newElementRect.top}px)`
							},
							{ transformOrigin: 'top left', transform: 'none' }
						],
						{ duration: 150, easing: 'ease' }
					)
					.finished.then(() => {
						elementCopy.style.position = '';
						elementCopy.style.top = '';
						elementCopy.style.left = '';
						elementCopy.style.width = '';
						elementCopy.style.pointerEvents = '';
						elementCopy.focus();
					})
					.catch(() => {
						/* ignore */
					});
			});
		}
	}

	class Bucket {
		constructor(bucketPool, id, bucketData) {
			this.id = id;
			this.bucketPool = bucketPool;

			this.el = this.htmlBucket(bucketData.label ?? '', bucketData.removable ?? 0, bucketData.indices);

			if (bucketData.isUniversalSet) bucketPool.universalSetContainer?.append(this.el);
			else bucketPool.bucketContainer.append(this.el);

			// Typeset any math content that may be in the added html.
			if (window.MathJax) window.MathJax.typesetPromise?.([this.el]);

			const options = {
				group: { name: bucketPool.answerName },
				animation: 150,
				onEnd: (evt) => {
					evt.item.focus();
					this.bucketPool.updateAnswerInput();
				}
			};

			if (bucketPool.showUniversalSet) {
				if (bucketData.isUniversalSet) {
					options.sort = false;
					options.group.pull = 'clone';
					options.group.put = false;
				} else {
					options.removeOnSpill = true;
					options.group.put = (to, _from, dragEl) => !to.toArray().some((id) => id === dragEl.dataset.id);
				}
			}

			this.sortable = Sortable.create(this.ddList, options);
		}

		htmlBucket(label, removable, indices = []) {
			const bucketElement = document.createElement('div');
			bucketElement.classList.add('dd-bucket');

			const bucketLabel = document.createElement('div');
			bucketLabel.classList.add('dd-bucket-label');
			bucketLabel.innerHTML =
				label || (this.bucketPool.labelFormat ? this.bucketPool.labelFormat.replace(/%s/, this.id + 1) : '');

			this.ddList = document.createElement('div');
			this.ddList.classList.add('dd-list');

			bucketElement.append(bucketLabel, this.ddList);

			for (const index of indices) {
				if (index < 0 || index > (this.bucketPool.itemList?.length ?? 0)) continue;

				const listElement = document.createElement('div');
				listElement.classList.add('dd-item');
				listElement.role = 'button';
				listElement.draggable = true;
				listElement.tabIndex = 0;
				listElement.dataset.id = index;
				listElement.innerHTML = this.bucketPool.itemList?.[index] ?? '';

				this.ddList.append(listElement);
			}

			bucketElement.style.backgroundColor = `hsl(${(100 + this.id * 100) % 360} 40% 90%)`;

			// The first bucket is not allowed to be removable.
			if (this.id !== 0 && removable) {
				const removeButton = document.createElement('button');
				removeButton.type = 'button';
				removeButton.classList.add('btn', 'btn-secondary', 'dd-remove-bucket-button');
				removeButton.textContent = this.bucketPool.removeButtonText;

				removeButton.addEventListener('click', () => {
					const firstBucketListItemIds = this.bucketPool.buckets[0].sortable.toArray();
					for (const item of this.items) {
						if (typeof item.dataset.id !== 'undefined' && !firstBucketListItemIds.includes(item.dataset.id))
							this.bucketPool.buckets[0].ddList.append(item);
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

		get items() {
			return Array.from(this.ddList.children);
		}

		hasItem(id) {
			return this.items.some((i) => i.dataset.id === id);
		}

		// Swap the position of two list items and animate the change.
		swapItems(element1, element2) {
			const listIds = this.sortable.toArray();
			const element1Index = listIds.findIndex((i) => i === element1.dataset.id);
			const element2Index = this.sortable.toArray().findIndex((i) => i === element2.dataset.id);
			if (element1Index === -1 || element2Index === -1) return;
			[listIds[element1Index], listIds[element2Index]] = [listIds[element2Index], listIds[element1Index]];
			this.sortable.sort(listIds, true);
			element1.focus();
		}

		// Remove a list item and animate the remaining list items moving up to fill its place.
		removeItem(element) {
			const listIds = this.sortable.toArray();
			const elementIndex = listIds.findIndex((i) => i === element.dataset.id);
			if (elementIndex === -1) return;
			listIds.splice(elementIndex, 1);
			this.sortable.sort(listIds, true);
			element.remove();
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
				if (node instanceof HTMLElement) {
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
})();
