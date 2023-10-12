(() => {
	class Accordion {
		constructor(details) {
			this.details = details;
			this.summary = details.querySelector('summary');
			this.content = details.querySelector('.accordion-body');
			this.animation = null;
			this.isClosing = false;
			this.isExpanding = false;
			this.summary.addEventListener('click', (e) => this.onClick(e));
		}

		onClick(e) {
			e.preventDefault();
			this.details.style.overflow = 'hidden';
			if (this.isClosing || !this.details.open) this.open();
			else if (this.isExpanding || this.details.open) this.shrink();
		}

		shrink() {
			this.isClosing = true;
			this.details.classList.add('closing');
			if (this.animation) this.animation.cancel();
			this.animation = this.details.animate(
				{ height: [`${this.details.offsetHeight}px`, `${this.summary.offsetHeight}px`] },
				{ duration: 200, easing: 'ease-in-out' }
			);
			this.animation.addEventListener('finish', () => this.onAnimationFinish(false), { once: true });
			this.animation.addEventListener('cancel', () => (this.isClosing = false), { once: true });
		}

		open() {
			this.details.style.height = `${this.details.offsetHeight}px`;
			this.details.open = true;
			window.requestAnimationFrame(() => this.expand());
		}

		expand() {
			this.isExpanding = true;
			if (this.animation) this.animation.cancel();
			this.animation = this.details.animate(
				{
					height: [
						`${this.details.offsetHeight}px`,
						`${this.summary.offsetHeight + this.content.offsetHeight}px`
					]
				},
				{ duration: 400, easing: 'ease-out' }
			);
			this.animation.addEventListener('finish', () => this.onAnimationFinish(true), { once: true });
			this.animation.addEventListener('cancel', () => (this.isExpanding = false), { once: true });
		}

		onAnimationFinish(isOpen) {
			this.details.open = isOpen;
			this.details.classList.remove('closing');
			this.animation = null;
			this.isClosing = false;
			this.isExpanding = false;
			this.details.style.height = this.details.style.overflow = '';
		}
	}

	document.querySelectorAll('.solution > details,.hint > details').forEach((details) => new Accordion(details));
})();
