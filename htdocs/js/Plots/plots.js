/* global JXG */

'use strict';

const PGplots = {
	async plot(boardContainerId, plotContents, options) {
		const drawBoard = (id) => {
			const boundingBox = options.board?.boundingBox ?? [-5, 5, 5, -5];

			// Disable highlighting for all elements.
			JXG.Options.elements.highlight = false;

			// Adjust layers to match standard TikZ layers.  The "axis" is bumped up a layer so it is above "axis
			// ticks".  The rest are on layer 3 by default, so they are moved up to main layer. The remaining layer
			// settings should be okay for now.
			JXG.Options.layer.axis = 3;
			JXG.Options.layer.polygon = 5;
			JXG.Options.layer.sector = 5;
			JXG.Options.layer.angle = 5;
			JXG.Options.layer.integral = 5;

			const board = JXG.JSXGraph.initBoard(
				id,
				JXG.merge(
					{
						title: options.board?.title ?? 'Graph',
						boundingBox,
						showCopyright: false,
						axis: false,
						drag: { enabled: false },
						showNavigation: options.board?.showNavigation ?? false,
						pan: { enabled: options.board?.showNavigation ?? false },
						zoom: { enabled: options.board?.showNavigation ?? false }
					},
					options.board?.overrideOptions ?? {}
				)
			);

			// The board now has its own clone of the options with the custom settings above which will apply for
			// anything created on the board. So reset the JSXGraph defaults so that other JSXGraph images on the page
			// don't get these settings.
			JXG.Options.elements.highlight = true;
			JXG.Options.layer.axis = 2;
			JXG.Options.layer.polygon = 3;
			JXG.Options.layer.sector = 3;
			JXG.Options.layer.angle = 3;
			JXG.Options.layer.integral = 3;

			const descriptionSpan = document.createElement('span');
			descriptionSpan.id = `${id}_description`;
			descriptionSpan.classList.add('visually-hidden');
			descriptionSpan.textContent = options.ariaDescription ?? 'Generated graph';
			board.containerObj.after(descriptionSpan);
			board.containerObj.setAttribute('aria-describedby', descriptionSpan.id);

			// Convert a decimal number into a fraction or mixed number.  This is basically the JXG.toFraction method
			// except that the "mixed" parameter is added, and it returns an improper fraction if mixed is false.
			const toFraction = (x, useTeX, mixed, order) => {
				const arr = JXG.Math.decToFraction(x, order);

				if (arr[1] === 0 && arr[2] === 0) {
					return '0';
				} else {
					let str = '';
					// Sign
					if (arr[0] < 0) str += '-';
					if (arr[2] === 0) {
						// Integer
						str += arr[1];
					} else if (!(arr[2] === 1 && arr[3] === 1)) {
						// Proper fraction
						if (mixed) {
							if (arr[1] !== 0) str += arr[1] + ' ';
							if (useTeX) str += `\\frac{${arr[2]}}{${arr[3]}}`;
							else str += `${arr[2]}/${arr[3]}`;
						} else {
							if (useTeX) str += `\\frac{${arr[3] * arr[1] + arr[2]}}{${arr[3]}}`;
							else str += `${arr[3] * arr[1] + arr[2]}/${arr[3]}`;
						}
					}
					return str;
				}
			};

			// Override the default axis generateLabelText method so that 0 is displayed
			// using MathJax if the axis is configured to show tick labels using MathJax.
			const generateLabelText = function (tick, zero, value) {
				if (JXG.exists(value)) return this.formatLabelText(value);
				const distance = this.getDistanceFromZero(zero, tick);
				return this.formatLabelText(Math.abs(distance) < JXG.Math.eps ? 0 : distance / this.visProp.scale);
			};

			const trimTrailingZeros = (value) => {
				if (value.indexOf('.') > -1 && value.endsWith('0')) {
					value = value.replace(/0+$/, '');
					// Remove the decimal if it is now at the end.
					value = value.replace(/\.$/, '');
				}
				return value;
			};

			// Override the formatLabelText method for the axes ticks so that
			// better number formats can be used for tick labels.
			const formatLabelText = function (value) {
				let labelText;

				if (JXG.isNumber(value)) {
					if (this.visProp.label.format === 'fraction' || this.visProp.label.format === 'mixed') {
						labelText = toFraction(
							value,
							this.visProp.label.usemathjax,
							this.visProp.label.format === 'mixed'
						);
					} else if (this.visProp.label.format === 'scinot') {
						const [mantissa, exponent] = value.toExponential(this.visProp.digits).toString().split('e');
						labelText = this.visProp.label.usemathjax
							? `${trimTrailingZeros(mantissa)}\\cdot 10^{${exponent}}`
							: `${trimTrailingZeros(mantissa)} x 10^${exponent}`;
					} else {
						labelText = trimTrailingZeros(value.toFixed(this.visProp.digits).toString());
					}
				} else {
					labelText = value.toString();
				}

				if (this.visProp.scalesymbol.length > 0) {
					if (labelText === '1') labelText = this.visProp.scalesymbol;
					else if (labelText === '-1') labelText = `-${this.visProp.scalesymbol}`;
					else if (labelText !== '0') labelText = labelText + this.visProp.scalesymbol;
				}

				return this.visProp.label.usemathjax ? `\\(${labelText}\\)` : labelText;
			};

			board.suspendUpdate();

			// This axis provides the vertical grid lines.
			if (options.grid?.x) {
				board.create(
					'axis',
					[
						[options.xAxis?.min ?? -5, options.xAxis?.position ?? 0],
						[options.xAxis?.max ?? 5, options.xAxis?.position ?? 0]
					],
					JXG.merge(
						{
							anchor:
								options.xAxis?.location === 'top'
									? 'left'
									: options.xAxis?.location === 'bottom' || options.xAxis?.location === 'box'
										? 'right'
										: 'right left',
							position:
								options.xAxis?.location === 'middle'
									? options.board?.showNavigation
										? 'sticky'
										: 'static'
									: 'fixed',
							firstArrow: false,
							lastArrow: false,
							straightFirst: options.board?.showNavigation ? true : false,
							straightLast: options.board?.showNavigation ? true : false,
							highlight: false,
							strokeOpacity: 0,
							ticks: {
								drawLabels: false,
								drawZero: true,
								majorHeight: -1,
								minorHeight: -1,
								strokeColor: options.grid.color ?? '#808080',
								strokeOpacity: options.grid.opacity ?? 0.2,
								insertTicks: false,
								ticksDistance: options.xAxis?.ticks?.distance ?? 2,
								scale: options.xAxis?.ticks?.scale ?? 1,
								minorTicks: options.grid.x.minorGrids ? (options.xAxis?.ticks?.minorTicks ?? 3) : 0,
								ignoreInfiniteTickEndings: false,
								majorTickEndings: [
									!options.board?.showNavigation && boundingBox[1] > (options.yAxis?.max ?? 5)
										? 0
										: 1,
									!options.board?.showNavigation && boundingBox[3] < (options.yAxis?.min ?? -5)
										? 0
										: 1
								],
								tickEndings: [
									!options.board?.showNavigation && boundingBox[1] > (options.yAxis?.max ?? 5)
										? 0
										: 1,
									!options.board?.showNavigation && boundingBox[3] < (options.yAxis?.min ?? -5)
										? 0
										: 1
								]
							},
							withLabel: false
						},
						options.grid.x.overrideOptions ?? {}
					)
				);
			}

			// This axis provides the horizontal grid lines.
			if (options.grid?.y) {
				board.create(
					'axis',
					[
						[options.yAxis?.position ?? 0, options.yAxis?.min ?? -5],
						[options.yAxis?.position ?? 0, options.yAxis?.max ?? -5]
					],
					JXG.merge(
						{
							anchor:
								options.yAxis?.location === 'right'
									? 'right'
									: options.yAxis?.location === 'left' || options.yAxis?.location === 'box'
										? 'left'
										: 'right left',
							position:
								options.yAxis?.location === 'center'
									? options.board?.showNavigation
										? 'sticky'
										: 'static'
									: 'fixed',
							firstArrow: false,
							lastArrow: false,
							straightFirst: options.board?.showNavigation ? true : false,
							straightLast: options.board?.showNavigation ? true : false,
							highlight: false,
							strokeOpacity: 0,
							ticks: {
								drawLabels: false,
								drawZero: true,
								majorHeight: -1,
								minorHeight: -1,
								strokeColor: options.grid.color ?? '#808080',
								strokeOpacity: options.grid.opacity ?? 0.2,
								insertTicks: false,
								ticksDistance: options.yAxis?.ticks?.distance ?? 2,
								scale: options.yAxis?.ticks?.scale ?? 1,
								minorTicks: options.grid.y.minorGrids ? (options.yAxis?.ticks?.minorTicks ?? 3) : 0,
								ignoreInfiniteTickEndings: false,
								majorTickEndings: [
									!options.board?.showNavigation && boundingBox[0] < (options.xAxis?.min ?? -5)
										? 0
										: 1,
									!options.board?.showNavigation && boundingBox[2] > (options.xAxis?.max ?? 5) ? 0 : 1
								],
								tickEndings: [
									!options.board?.showNavigation && boundingBox[0] < (options.xAxis?.min ?? -5)
										? 0
										: 1,
									!options.board?.showNavigation && boundingBox[2] > (options.xAxis?.max ?? 5) ? 0 : 1
								]
							},
							withLabel: 0
						},
						options.grid.y.overrideOptions ?? {}
					)
				);
			}

			if (options.xAxis?.visible) {
				const xAxis = board.create(
					'axis',
					[
						[options.xAxis.min ?? -5, options.xAxis.position ?? 0],
						[options.xAxis.max ?? 5, options.xAxis.position ?? 0]
					],
					JXG.merge(
						{
							name: options.xAxis.name ?? '\\(x\\)',
							anchor:
								options.xAxis?.location === 'top'
									? 'left'
									: options.xAxis?.location === 'bottom' || options.xAxis?.location === 'box'
										? 'right'
										: 'right left',
							position:
								options.xAxis.location === 'middle'
									? options.board?.showNavigation
										? 'sticky'
										: 'static'
									: 'fixed',
							firstArrow: options.axesArrowsBoth ? { size: 7 } : false,
							lastArrow: { size: 7 },
							highlight: false,
							straightFirst: options.board?.showNavigation ? true : false,
							straightLast: options.board?.showNavigation ? true : false,
							withLabel: options.xAxis.location === 'middle' ? true : false,
							label: {
								anchorX: 'right',
								anchorY: 'middle',
								highlight: false,
								offset: [-5, -3],
								position: '100% left',
								useMathJax: true
							},
							ticks: {
								drawLabels: options.xAxis.ticks?.labels && options.xAxis.ticks?.show ? true : false,
								drawZero:
									options.board?.showNavigation ||
									!options.yAxis?.visible ||
									(options.yAxis.location === 'center' && (options.yAxis.position ?? 0) != 0) ||
									((options.yAxis.location === 'left' || options.yAxis.location === 'box') &&
										(options.yAxis.min ?? -5) != 0) ||
									(options.yAxis.location === 'right' && (options.yAxis.max ?? 5) != 0)
										? true
										: false,
								insertTicks: false,
								ticksDistance: options.xAxis.ticks?.distance ?? 2,
								scale: options.xAxis.ticks?.scale ?? 1,
								scaleSymbol: options.xAxis.ticks?.scaleSymbol ?? '',
								minorTicks: options.xAxis.ticks?.minorTicks ?? 3,
								majorHeight: options.xAxis.ticks?.show ? 8 : 0,
								minorHeight: options.xAxis.ticks?.show ? 5 : 0,
								strokeWidth: 1.5,
								majorTickEndings: [1, options.xAxis.location === 'box' ? 0 : 1],
								tickEndings: [1, options.xAxis.location === 'box' ? 0 : 1],
								digits: options.xAxis.ticks?.labelDigits ?? 2,
								label: {
									anchorX: 'middle',
									anchorY: options.xAxis.location === 'top' ? 'bottom' : 'top',
									offset: options.xAxis.location === 'top' ? [0, 4] : [0, -4],
									highlight: 0,
									...(options.mathJaxTickLabels ? { useMathJax: true, display: 'html' } : {}),
									format: options.xAxis.ticks?.labelFormat ?? 'decimal'
								}
							}
						},
						options.xAxis.overrideOptions ?? {}
					)
				);
				xAxis.defaultTicks.generateLabelText = generateLabelText;
				xAxis.defaultTicks.formatLabelText = formatLabelText;

				if (options.xAxis.location !== 'middle') {
					board.create(
						'text',
						[
							(xAxis.point1.X() + xAxis.point2.X()) / 2,
							options.xAxis.location === 'top' ? board.getBoundingBox()[1] : board.getBoundingBox()[3],
							options.xAxis.name ?? '\\(x\\)'
						],
						{
							anchorX: 'middle',
							anchorY: options.xAxis.location === 'top' ? 'top' : 'bottom',
							highlight: false,
							color: 'black',
							fixed: true,
							useMathJax: true
						}
					);
				}
			}

			if (options.yAxis?.visible) {
				const yAxis = board.create(
					'axis',
					[
						[options.yAxis.position ?? 0, options.yAxis.min ?? -5],
						[options.yAxis.position ?? 0, options.yAxis.max ?? -5]
					],
					JXG.merge(
						{
							name: options.yAxis.name ?? '\\(y\\)',
							anchor:
								options.yAxis?.location === 'right'
									? 'right'
									: options.yAxis?.location === 'left' || options.yAxis?.location === 'box'
										? 'left'
										: 'right left',
							position:
								options.yAxis.location === 'center'
									? options.board?.showNavigation
										? 'sticky'
										: 'static'
									: 'fixed',
							firstArrow: options.axesArrowsBoth ? { size: 7 } : false,
							lastArrow: { size: 7 },
							highlight: false,
							straightFirst: options.board?.showNavigation ? true : false,
							straightLast: options.board?.showNavigation ? true : false,
							withLabel: options.yAxis.location === 'center' ? true : false,
							label: {
								anchorX: 'middle',
								anchorY: 'top',
								highlight: false,
								distance: 1,
								offset: [5, 1],
								position: '100% right',
								useMathJax: true
							},
							ticks: {
								drawLabels: options.yAxis.ticks?.labels && options.yAxis.ticks?.show ? true : false,
								drawZero:
									options.board?.showNavigation ||
									!options.xAxis?.visible ||
									(options.xAxis.location === 'middle' && (options.xAxis.position ?? 0) != 0) ||
									((options.xAxis.location === 'bottom' || options.xAxis.location === 'box') &&
										(options.xAxis.min ?? -5) != 0) ||
									(options.xAxis.location === 'top' && (options.xAxis.max ?? 5) != 0)
										? true
										: false,
								insertTicks: false,
								ticksDistance: options.yAxis.ticks?.distance ?? 2,
								scale: options.yAxis.ticks?.scale ?? 1,
								scaleSymbol: options.yAxis.ticks?.scaleSymbol ?? '',
								minorTicks: options.yAxis.ticks?.minorTicks ?? 3,
								majorHeight: options.yAxis.ticks?.show ? 8 : 0,
								minorHeight: options.yAxis.ticks?.show ? 5 : 0,
								strokeWidth: 1.5,
								majorTickEndings: [options.yAxis.location === 'box' ? 0 : 1, 1],
								tickEndings: [options.yAxis.location === 'box' ? 0 : 1, 1],
								digits: options.yAxis.ticks?.labelDigits ?? 2,
								label: {
									anchorX: options.yAxis.location === 'right' ? 'left' : 'right',
									anchorY: 'middle',
									offset: options.yAxis.location === 'right' ? [6, 0] : [-6, 0],
									highlight: false,
									...(options.mathJaxTickLabels ? { useMathJax: true, display: 'html' } : {}),
									format: options.yAxis.ticks?.labelFormat ?? 'decimal'
								}
							}
						},
						options.yAxis.overrideOptions ?? {}
					)
				);
				yAxis.defaultTicks.generateLabelText = generateLabelText;
				yAxis.defaultTicks.formatLabelText = formatLabelText;

				if (options.yAxis.location !== 'center') {
					board.create(
						'text',
						[
							options.yAxis.location === 'right' ? boundingBox[2] : boundingBox[0],
							(yAxis.point1.Y() + yAxis.point2.Y()) / 2,
							options.yAxis.name ?? '\\(y\\)'
						],
						{
							anchorX: 'middle',
							anchorY: options.yAxis.location === 'right' ? 'bottom' : 'top',
							rotate: 90,
							highlight: 0,
							color: 'black',
							fixed: 1,
							useMathJax: 1
						}
					);
				}
			}

			plotContents(board);

			board.unsuspendUpdate();

			return board;
		};

		const container = document.getElementById(boardContainerId);
		if (!container) return;

		const drawPromise = (id) =>
			new Promise((resolve) => {
				if (container.offsetWidth === 0) {
					setTimeout(async () => resolve(await drawPromise(id)), 100);
					return;
				}
				resolve(drawBoard(id));
			});

		await drawPromise(boardContainerId);

		let jsxBoard = null;
		container.addEventListener('shown.imageview', async () => {
			document
				.getElementById(`magnified-${boardContainerId}`)
				?.classList.add(...Array.from(container.classList).filter((c) => c !== 'image-view-elt'));
			jsxBoard = await drawPromise(`magnified-${boardContainerId}`);
		});
		container.addEventListener('resized.imageview', () => {
			jsxBoard?.resizeContainer(jsxBoard.containerObj.clientWidth, jsxBoard.containerObj.clientHeight, true);
		});
		container.addEventListener('hidden.imageview', () => {
			if (jsxBoard) JXG.JSXGraph.freeBoard(jsxBoard);
			jsxBoard = null;
		});
	}
};
