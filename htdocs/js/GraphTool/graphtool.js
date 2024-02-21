/* global JXG */

'use strict';

window.graphTool = (containerId, options) => {
	// Do nothing if the graph has already been created.
	if (document.getElementById(`${containerId}_graph`)) return;

	const gt = {};

	gt.graphContainer = document.getElementById(containerId);
	if (!gt.graphContainer) return;
	if (gt.graphContainer.offsetWidth === 0) {
		setTimeout(() => window.graphTool(containerId, options), 100);
		return;
	}

	// Semantic color control
	gt.color = {
		// dark blue
		// > 13:1 with white
		curve: '#0000a6',

		// blue
		// > 9:1 with white
		focusCurve: '#0000f5',

		// medium purple
		// 3:1 with white
		// 4.5:1 with #0000a6
		// > 3:1 with #0000f5
		fill: '#a384e5',

		// strict contrast ratios are less important for these colors
		point: 'orange',
		pointHighlight: 'yellow',
		pointHighlightDarker: '#cc8400', // color.adjust(orange, $lightness: -10%)
		underConstruction: 'orange',
		underConstructionFixed: JXG.palette.red // defined to be '#d55e00'
	};

	gt.definingPointAttributes = {
		size: 3,
		fixed: false,
		highlight: true,
		withLabel: false,
		strokeWidth: 1,
		strokeColor: gt.color.focusCurve,
		fillColor: gt.color.point,
		highlightStrokeWidth: 1,
		highlightStrokeColor: gt.color.focusCurve,
		highlightFillColor: gt.color.pointHighlight
	};

	gt.options = options;
	gt.snapSizeX = options.snapSizeX ? options.snapSizeX : 1;
	gt.snapSizeY = options.snapSizeY ? options.snapSizeY : 1;
	gt.isStatic = options.isStatic ? true : false;
	if (!(options.availableTools instanceof Array))
		options.availableTools = [
			'LineTool',
			'CircleTool',
			'VerticalParabolaTool',
			'HorizontalParabolaTool',
			'FillTool',
			'SolidDashTool'
		];

	// This is the icon used for the fill tool and fill graph object.
	gt.fillIcon = (color) =>
		'data:image/svg+xml,' +
		encodeURIComponent(
			"<svg xmlns:svg='http://www.w3.org/2000/svg' xmlns='http://www.w3.org/2000/svg' version='1.1' " +
				"viewBox='0 0 32 32' height='32px' width='32px'><g>" +
				"<path d='m 13.466084,10.267728 -4.9000003,8.4 4.9000003,4.9 8.4,-4.9 z' opacity='1' " +
				`fill='${color}' fill-opacity='1' stroke='#000000' stroke-width='1.3' ` +
				"stroke-linecap='butt' stroke-linejoin='miter' stroke-opacity='1' stroke-miterlimit='4' " +
				"stroke-dasharray='none' />" +
				"<path d='M 16.266084,15.780798 V 6.273173' fill='none' stroke='#000000' stroke-width='1.38' " +
				"stroke-linecap='round' stroke-linejoin='miter' stroke-miterlimit='4' stroke-dasharray='none' " +
				"stroke-opacity='1' />" +
				"<path d='m 20,16 c 0,0 2,-1 3,0 1,0 1,1 2,2 0,1 0,2 0,3 0,1 0,2 0,2 0,0 -1,0 -1,0 -1,-1 -1,-1 -1,-2 " +
				"0,-1 0,-1 -1,-2 0,-1 0,-2 -1,-2 -1,-1 -2,-1 -1,-1 z' fill='#0900ff' fill-opacity='1' stroke='#000000' " +
				"stroke-width='0.7px' stroke-linecap='butt' stroke-linejoin='miter' stroke-opacity='1' />" +
				'</g></svg>'
		);

	if ('htmlInputId' in options) gt.html_input = document.getElementById(options.htmlInputId);
	const cfgOptions = {
		title: 'WeBWorK Graph Tool',
		description: options.ariaDescription ?? 'Interactively graph objects',
		showCopyright: false,
		pan: { enabled: false },
		zoom: { enabled: false },
		showNavigation: false,
		boundingBox: [-10, 10, 10, -10],
		defaultAxes: {},
		axis: {
			ticks: {
				label: { highlight: false },
				insertTicks: false,
				ticksDistance: 2,
				minorTicks: 1,
				minorHeight: 6,
				majorHeight: 6,
				tickEndings: [1, 1]
			},
			highlight: false,
			firstArrow: { size: 7 },
			lastArrow: { size: 7 },
			straightFirst: false,
			straightLast: false,
			fixed: true
		},
		grid: { gridX: gt.snapSizeX, gridY: gt.snapSizeY },
		keyboard: {
			enabled: true,
			dx: gt.snapSizeX,
			dy: gt.snapSizeY,
			panShift: false
		}
	};

	// Merge options that are set by the problem.
	if (typeof options.JSXGraphOptions === 'object') JXG.merge(cfgOptions, options.JSXGraphOptions);

	const setupBoard = () => {
		gt.board = JXG.JSXGraph.initBoard(`${containerId}_graph`, cfgOptions);
		gt.board.suspendUpdate();

		// Move the axes defining points to the end so that the arrows go to the board edges.
		const bbox = gt.board.getBoundingBox();
		gt.board.defaultAxes.x.point1.setPosition(JXG.COORDS_BY_USER, [bbox[0], 0]);
		gt.board.defaultAxes.x.point2.setPosition(JXG.COORDS_BY_USER, [bbox[2], 0]);

		if (options.numberLine) {
			gt.board.defaultAxes.y.point1.setPosition(JXG.COORDS_BY_USER, [0, 0]);
			gt.board.defaultAxes.y.point2.setPosition(JXG.COORDS_BY_USER, [0, 0]);
		} else {
			gt.board.defaultAxes.y.point1.setPosition(JXG.COORDS_BY_USER, [0, bbox[3]]);
			gt.board.defaultAxes.y.point2.setPosition(JXG.COORDS_BY_USER, [0, bbox[1]]);
		}

		// Add labels to the x and y axes.
		if (options.xAxisLabel) {
			gt.board.create(
				'text',
				[
					() => gt.board.getBoundingBox()[2] - 3 / gt.board.unitX,
					() => 1.5 / gt.board.unitY,
					() => `\\(${options.xAxisLabel}\\)`
				],
				{ anchorX: 'right', anchorY: 'bottom', highlight: false, color: 'black', fixed: true, useMathJax: true }
			);
		}
		if (options.yAxisLabel && !options.numberLine) {
			gt.board.create(
				'text',
				[
					() => 4.5 / gt.board.unitX,
					() => gt.board.getBoundingBox()[1] + 2.5 / gt.board.unitY,
					() => `\\(${options.yAxisLabel}\\)`
				],
				{ anchorX: 'left', anchorY: 'top', highlight: false, color: 'black', fixed: true, useMathJax: true }
			);
		}

		// Add an empty text that will hold the cursor position.
		gt.current_pos_text = options.numberLine
			? gt.board.create(
					'text',
					[
						() => gt.board.getBoundingBox()[0] + 10 / gt.board.unitX,
						() => gt.board.getBoundingBox()[1] - 2 / gt.board.unitY,
						() => ''
					],
					{ anchorX: 'left', anchorY: 'top', fixed: true, useMathJax: true }
				)
			: gt.board.create(
					'text',
					[
						() => gt.board.getBoundingBox()[2] - 5 / gt.board.unitX,
						() => gt.board.getBoundingBox()[3] + 5 / gt.board.unitY,
						() => ''
					],
					{ anchorX: 'right', anchorY: 'bottom', fixed: true, useMathJax: true }
				);

		// Overwrite the popup infobox for points.
		gt.board.highlightInfobox = (_x, _y, el) => gt.board.highlightCustomInfobox('', el);

		if (!gt.isStatic) {
			gt.graphContainer.tabIndex = -1;
			gt.board.containerObj.tabIndex = -1;

			gt.board.on('move', (e) => {
				if (e.type === 'keydown') {
					if (
						gt.activeTool === gt.selectTool &&
						gt.board.containerObj.contains(document.activeElement) &&
						gt.graphedObjs.length
					) {
						gt.graphedObjs.some((obj) => {
							const el = obj.definingPts.find((point) => point.rendNode === e.target);
							if (el) {
								// None of the current graph objects use the handleKeyEvent handler anymore.  This is
								// still provided in case a new graph object is written that needs it.  However, in that
								// case it is the responsibility of the calling method to call gt.updateObjects() and
								// gt.updateText() when it is finished if those are needed.
								obj.handleKeyEvent(e, el);

								if (!gt.selectedObj || !gt.selectedObj.updateTextCoords(el.coords))
									gt.setTextCoords(el.coords.usrCoords[1], el.coords.usrCoords[2]);
							}
						});
					} else {
						gt.activeTool?.updateHighlights(e);
					}
				} else if (e.type === 'pointermove') {
					if (gt.activeTool?.updateHighlights(e)) return;

					const coords = gt.getMouseCoords(e);
					if (!gt.selectedObj || !gt.selectedObj.updateTextCoords(coords))
						gt.setTextCoords(coords.usrCoords[1], coords.usrCoords[2]);
				}
			});

			gt.hasFocus = false;
			gt.objectFocusSet = false;

			gt.board.containerObj.addEventListener('focus', () => (gt.hasFocus = true));

			gt.graphContainer.addEventListener('focusin', (e) => {
				e.preventDefault();
				e.stopPropagation();
				if (!gt.graphContainer.contains(e.relatedTarget) && !gt.hasFocus) {
					// Focus has entered from outside the container.
					if (e.target === gt.graphContainer || e.target === gt.selectTool.button) {
						// In this case focus has entered the container from above.
						if (gt.graphedObjs.length) {
							gt.objectFocusSet = true;
							gt.selectedObj = gt.graphedObjs[0];
							gt.selectedObj.focusPoint = gt.selectedObj?.definingPts[0];
						} else {
							gt.objectFocusSet = false;
							gt.buttonBox.querySelectorAll('.gt-button')[1]?.focus();
						}
					} else {
						// In this case focus has entered the container from below.
						gt.objectFocusSet = false;
						setTimeout(() => e.target?.focus());
					}

					gt.hasFocus = true;
					if (!gt.activeTool) gt.selectTool.activate();
				} else if (gt.board.containerObj.contains(e.relatedTarget) && gt.graphContainer === e.target) {
					// If the graph container is the explicit target and focus is coming from something on the board,
					// then send focus back to the object on the board it came from.
					e.relatedTarget.focus();
				} else {
					gt.objectFocusSet = false;
				}
			});

			gt.board.containerObj.addEventListener('focusin', (e) => {
				e.preventDefault();
				e.stopPropagation();

				if (e.target === gt.board.containerObj) {
					if (gt.board.containerObj.contains(e.relatedTarget)) {
						// Place the focus back onto where it was coming from.
						e.relatedTarget.focus();
						return;
					}
				}

				// If a defining point is the target, then update the focus point for the object it belongs to.
				gt.graphedObjs.some((obj) =>
					obj.definingPts.some((point) => {
						if (point.rendNode === e.target) {
							obj.focusPoint = point;
							return true;
						}
					})
				);

				if (
					e.relatedTarget !== gt.board.containerObj &&
					(gt.buttonBox.contains(e.relatedTarget) ||
						(gt.board.containerObj.contains(e.relatedTarget) &&
							gt.graphedObjs.every((obj) =>
								obj.definingPts.every((point) => point.rendNode !== e.relatedTarget)
							))) &&
					gt.graphedObjs.some((obj) => obj.definingPts.some((point) => point.rendNode === e.target))
				) {
					if (!gt.objectFocusSet) {
						gt.objectFocusSet = true;
						const lastSelected = gt.selectedObj;
						gt.selectedObj = gt.graphedObjs[gt.graphedObjs.length - 1];
						gt.selectedObj.focusPoint = gt.selectedObj.definingPts[gt.selectedObj.definingPts.length - 1];
						gt.selectedObj.focus();
						if (lastSelected !== gt.selectedObj) lastSelected?.blur();
					}
				} else if (!gt.board.containerObj.contains(e.relatedTarget)) {
					let lastSelected;
					if (!gt.hasFocus && gt.graphedObjs.length) {
						lastSelected = gt.selectedObj;
						if (gt.graphContainer.contains(e.relatedTarget)) {
							gt.selectedObj = gt.graphedObjs[gt.graphedObjs.length - 1];
							gt.selectedObj.focusPoint =
								gt.selectedObj.definingPts[gt.selectedObj.definingPts.length - 1];
						} else {
							gt.selectedObj = gt.graphedObjs[0];
							gt.selectedObj.focusPoint = gt.selectedObj?.definingPts[0];
						}
						gt.objectFocusSet = true;
					} else gt.objectFocusSet = false;

					gt.hasFocus = true;
					if (!gt.activeTool) gt.selectTool.activate();
					if (lastSelected !== gt.selectedObj) lastSelected?.blur();
				}
			});

			gt.board.containerObj.addEventListener('pointerdown', (e) => {
				if (gt.activeTool) return;
				const coords = gt.getMouseCoords(e).scrCoords.slice(1);

				// Check to see if a defining point of a graphed object was clicked on.
				// If so focus the object and that point.
				for (const obj of gt.graphedObjs) {
					if (obj.baseObj.rendNode === e.target) {
						for (const point of obj.definingPts) {
							if (point.rendNode === e.target) {
								gt.hasFocus = true;
								gt.selectedObj = obj;
								gt.selectTool.activate();
								// If a focus point was found, then resend this event so that jsxgraph
								// will start a drag if the pointer is held down.
								obj.focusPoint?.rendNode.dispatchEvent(new PointerEvent('pointerdown', e));
								return;
							}
						}
					}
				}

				// Check to see if the pointer is on an object, in which case focus that.  This focuses the first object
				// found searching in the order that the objecs were graphed.
				for (const obj of gt.graphedObjs) {
					if (obj.baseObj.hasPoint(...coords)) {
						for (const point of obj.definingPts) {
							if (point.hasPoint(...coords)) {
								obj.focusPoint = point;
								break;
							}
						}
						gt.hasFocus = true;
						gt.selectedObj = obj;
						gt.selectTool.activate();
						// If a focus point was found, then resend this event so that jsxgraph
						// will start a drag if the pointer is held down.
						obj.focusPoint?.rendNode.dispatchEvent(new PointerEvent('pointerdown', e));
						return;
					}
				}
			});

			gt.graphContainer.addEventListener('focusout', (e) => {
				if (!gt.graphContainer.contains(e.relatedTarget)) {
					// Focus is being lost to something outside the container.
					// So close any incomplete confirmation, deactivate any active tool, and blur any selected object.
					gt.confirm.dispose?.(e);
					gt.hasFocus = false;
					gt.objectFocusSet = false;
					gt.activeTool?.deactivate();
					delete gt.activeTool;
					gt.updateHelp();
				}
			});

			gt.graphContainer.addEventListener('keydown', (e) => {
				for (const tool of gt.tools) tool.handleKeyEvent(e);

				if (!gt.buttonBox.contains(document.activeElement) && e.key === 'N' && e.shiftKey) {
					// Shift-N moves focus to the first tool button after the select button unless the tool bar already
					// has the focused element. (The select button is disabled at this point, so focus can't go there.)
					gt.buttonBox.querySelectorAll('.gt-button:not([disabled])')[0]?.focus();
				} else if (e.key === 'Escape' && gt.activeTool !== gt.selectTool) {
					// Escape deactivates any active tool except the select tool.
					gt.selectTool.activate();
				} else if (e.key === 'Delete' && e.ctrlKey) {
					// If the Ctrl-Delete is pressed, then ask to delete all objects.
					gt.clearAll();
				} else if (e.key === 'Delete' && gt.activeTool === gt.selectTool) {
					// If the select tool is active and Delete is pressed, then ask to delete the selected object.
					gt.deleteSelected();
				}
			});
		}

		const resize = () => {
			// If the container does not have width or height (for example if the graph is inside a closed scaffold when
			// the window is resized), then delay resizing the graph until the container does have width and height.
			if (!gt.board.containerObj.offsetWidth || !gt.board.containerObj.offsetHeight) {
				setTimeout(resize, 1000);
				return;
			}
			if (
				gt.board.canvasWidth != gt.board.containerObj.offsetWidth - 2 ||
				gt.board.canvasHeight != gt.board.containerObj.offsetHeight - 2
			) {
				gt.board.resizeContainer(
					gt.board.containerObj.offsetWidth - 2,
					gt.board.containerObj.offsetHeight - 2,
					true
				);
				gt.graphedObjs.forEach((object) => object.onResize());
				gt.staticObjs.forEach((object) => object.onResize());
			}
		};

		window.addEventListener('resize', resize);

		gt.drawSolid = true;
		gt.graphedObjs = [];
		gt.staticObjs = [];

		gt.board.unsuspendUpdate();
	};

	// Some utility functions.
	gt.snapRound = (x, snap, precision = 10 ** 5) => Math.round(Math.round(x / snap) * snap * precision) / precision;

	// Convert a decimal number into a fraction or mixed number with denominator at most 10 ** 8.
	gt.toLatexFrac = (x, mixed = false, _snapSize = gt.snapSizeX) => {
		const sign = x ? Math.abs(x) / x : 1,
			int = mixed ? Math.trunc(sign * x) : 0;
		let a = 0,
			step = sign * x - int,
			h0 = 1,
			h1 = a,
			k0 = 0,
			k1 = 1;

		while (Math.abs(step - a) >= JXG.Math.eps) {
			step = 1 / (step - a);
			a = Math.trunc(step);
			const [newh, newk] = [a * h1 + h0, a * k1 + k0];
			if (newk > 10 ** 8) break;
			[h0, h1, k0, k1] = [h1, newh, k1, newk];
		}

		if (k1 === 1) return mixed ? `${sign * int}` : `${sign * h1}`;
		else if (int === 0) return `${sign === -1 ? '-' : ''}\\frac{${h1}}{${k1}}`;
		else return `${sign * int}\\frac{${h1}}{${k1}}`;
	};

	gt.setTextCoords = options.showCoordinateHints
		? options.numberLine
			? (x) => {
					const bbox = gt.board.getBoundingBox();
					const xSnap = gt.snapRound(x, gt.snapSizeX);
					if (xSnap <= bbox[0]) gt.current_pos_text.setText(() => '\\(-\\infty\\)');
					else if (xSnap >= bbox[2]) gt.current_pos_text.setText(() => '\\(\\infty\\)');
					else {
						if (options.coordinateHintsTypeX === 'mixed' || options.coordinateHintsTypeX === 'fraction') {
							const text = gt.toLatexFrac(
								gt.snapRound(x, gt.snapSizeX, 10 ** 13),
								options.coordinateHintsTypeX === 'mixed'
							);
							gt.current_pos_text.setText(() => `\\(${text}\\)`);
						} else gt.current_pos_text.setText(() => `\\(${xSnap}\\)`);
					}
				}
			: (x, y) => {
					const xText =
						options.coordinateHintsTypeX === 'mixed' || options.coordinateHintsTypeX === 'fraction'
							? gt.toLatexFrac(
									gt.snapRound(x, gt.snapSizeX, 10 ** 13),
									options.coordinateHintsTypeX === 'mixed'
								)
							: gt.snapRound(x, gt.snapSizeX);
					const yText =
						options.coordinateHintsTypeY === 'mixed' || options.coordinateHintsTypeY === 'fraction'
							? gt.toLatexFrac(
									gt.snapRound(y, gt.snapSizeY, 10 ** 13),
									options.coordinateHintsTypeY === 'mixed',
									gt.snapSizeY
								)
							: gt.snapRound(y, gt.snapSizeY);
					gt.current_pos_text.setText(() => `\\(\\left(${xText}, ${yText}\\right)\\)`);
				}
		: () => {};

	gt.updateText = () => {
		gt.html_input.value = gt.graphedObjs.reduce(
			(val, obj) => `${val}${val.length ? ',' : ''}{${obj.stringify()}}`,
			''
		);
	};

	gt.setMessageContent = (newContent, confirmation = false) =>
		new Promise((resolve, _reject) => {
			if (gt.confirmationActive) return resolve();
			gt.confirmationActive = confirmation;

			clearInterval(gt.setMessageContent.IntervalId);
			for (const message of gt.messageBox.querySelectorAll('.gt-message-content'))
				message.classList.remove('gt-message-fade');
			gt.setMessageContent.IntervalId = setTimeout(() => {
				requestAnimationFrame(() => {
					while (gt.messageBox.firstChild) gt.messageBox.firstChild.remove();
					if (newContent) {
						gt.messageBox.append(newContent);
						newContent.classList.add('gt-message-content');
						setTimeout(() => newContent.classList.add('gt-message-content', 'gt-message-fade'));

						if (window.MathJax) {
							MathJax.startup.promise = MathJax.startup.promise.then(() =>
								MathJax.typesetPromise([newContent])
							);
						}
					}

					resolve();
				});
			}, 100);
		});

	gt.setMessageText = (content) => {
		if (gt.confirmationActive || !gt.helpEnabled) return;

		const newMessage = content instanceof Array ? content.join(' ') : content;
		if (newMessage) {
			const par = document.createElement('p');
			par.textContent = newMessage;
			gt.setMessageContent(par);
		} else {
			gt.setMessageContent();
		}
	};

	gt.updateHelp = () => {
		if (gt.confirmationActive || !gt.helpEnabled) return;

		gt.setMessageText(
			gt.tools
				.map((tool) => (typeof tool.helpText === 'function' ? tool.helpText() : tool.helpText || ''))
				.filter((helpText) => !!helpText)
		);
	};

	gt.updateUI = () => {
		gt.deleteButton.disabled = !gt.selectedObj;
		gt.clearButton.disabled = !gt.graphedObjs.length;
		gt.updateHelp();
	};

	gt.getMouseCoords = (e) => {
		return new JXG.Coords(
			JXG.COORDS_BY_SCREEN,
			gt.board.getMousePosition(e, e[JXG.touchProperty] ? 0 : undefined),
			gt.board
		);
	};

	gt.sign = (x) => {
		x = +x;
		if (Math.abs(x) < JXG.Math.eps) return 0;
		return x > 0 ? 1 : -1;
	};

	// These return true if the given x coordinate is off the board or within epsilon of the edge of the board.
	gt.isPosInfX = (x) => x >= gt.board.getBoundingBox()[2] - JXG.Math.eps;
	gt.isNegInfX = (x) => x <= gt.board.getBoundingBox()[0] + JXG.Math.eps;

	// Use this instead of gt.board.hasPoint.  That method uses strict inequality.
	// Using inequality with equality allows points on the edge of the board.
	gt.boardHasPoint = (x, y) => {
		let px = x,
			py = y;
		const bbox = gt.board.getBoundingBox();

		if (JXG.exists(x) && JXG.isArray(x.usrCoords)) {
			px = x.usrCoords[1];
			py = x.usrCoords[2];
		}

		return JXG.isNumber(px) && JXG.isNumber(py) && bbox[0] <= px && px <= bbox[2] && bbox[1] >= py && py >= bbox[3];
	};

	gt.pointRegexp = /\( *(-?[0-9]*(?:\.[0-9]*)?), *(-?[0-9]*(?:\.[0-9]*)?) *\)/g;

	// Prevent a point from being moved off the board by a drag. If a paired point is provided, then also prevent the
	// point from being moved into the same position as the paired point by a drag.  Note that when this method is
	// called, the point has already been moved by JSXGraph.  This prevents lines and circles from being made
	// degenerate.
	gt.adjustDragPosition = (e, point, pairedPoint) => {
		if (
			(point.X() == pairedPoint?.X() && point.Y() == pairedPoint?.Y()) ||
			!gt.boardHasPoint(point.X(), point.Y())
		) {
			const bbox = gt.board.getBoundingBox();

			// Clamp the coordinates to the board.
			let x = point.X() < bbox[0] ? bbox[0] : point.X() > bbox[2] ? bbox[2] : point.X();
			let y = point.Y() < bbox[3] ? bbox[3] : point.Y() > bbox[1] ? bbox[1] : point.Y();

			// Adjust position of the point if it has the same coordinates as its paired point.
			if (pairedPoint && x === pairedPoint.X() && y === pairedPoint.Y()) {
				let xDir, yDir;

				if (e.type === 'pointermove') {
					const coords = gt.getMouseCoords(e);
					const x_trans = coords.usrCoords[1] - pairedPoint.X(),
						y_trans = coords.usrCoords[2] - pairedPoint.Y();
					[xDir, yDir] =
						Math.abs(x_trans) < Math.abs(y_trans) ? [0, y_trans < 0 ? -1 : 1] : [x_trans < 0 ? -1 : 1, 0];
				} else if (e.type === 'keydown') {
					xDir = e.key === 'ArrowLeft' ? -1 : e.key === 'ArrowRight' ? 1 : 0;
					yDir = e.key === 'ArrowUp' ? 1 : e.key === 'ArrowDown' ? -1 : 0;
				}

				y += yDir * gt.snapSizeY;
				x += xDir * gt.snapSizeX;

				// If the computed new coordinates are off the board,
				// then move the coordinates the other direction instead.
				if (x < bbox[0]) x = bbox[0] + gt.snapSizeX;
				else if (x > bbox[2]) x = bbox[2] - gt.snapSizeX;
				if (y < bbox[3]) y = bbox[3] + gt.snapSizeY;
				else if (y > bbox[1]) y = bbox[1] - gt.snapSizeY;
			}

			point.setPosition(JXG.COORDS_BY_USER, [x, y]);
		}
	};

	gt.pairedPointDrag = (e, point) => {
		gt.adjustDragPosition(e, point, point.paired_point);
		gt.updateObjects();
		gt.updateText();
	};

	// Prevent a point from being moved off the board by a drag, and prevent the point from being moved onto the same
	// horizontal or vertical line as its paired point by a drag. Note that when this method is called, the point has
	// already been moved by JSXGraph.  This prevents parabolas from being made degenerate.
	gt.adjustDragPositionRestricted = (e, point, pairedPoint) => {
		if (point.X() == pairedPoint?.X() || point.Y() == pairedPoint?.Y() || !gt.boardHasPoint(point.X(), point.Y())) {
			const bbox = gt.board.getBoundingBox();

			// Clamp the coordinates to the board.
			let x = point.X() < bbox[0] ? bbox[0] : point.X() > bbox[2] ? bbox[2] : point.X();
			let y = point.Y() < bbox[3] ? bbox[3] : point.Y() > bbox[1] ? bbox[1] : point.Y();

			if (pairedPoint) {
				// Adjust the position of the point if it is on the same
				// horizontal or vertical line as its paired point.
				let xDir, yDir;

				if (e.type === 'pointermove') {
					const coords = gt.getMouseCoords(e);
					xDir = coords.usrCoords[1] > pairedPoint.X() ? 1 : -1;
					yDir = coords.usrCoords[2] > pairedPoint.Y() ? 1 : -1;
				} else if (e.type === 'keydown') {
					xDir = e.key === 'ArrowLeft' ? -1 : e.key === 'ArrowRight' ? 1 : 0;
					yDir = e.key === 'ArrowUp' ? 1 : e.key === 'ArrowDown' ? -1 : 0;
				}

				if (x == pairedPoint.X()) x += xDir * gt.snapSizeX;
				if (y == pairedPoint.Y()) y += yDir * gt.snapSizeY;

				// If the computed new coordinates are off the board,
				// then move the coordinates the other direction instead.
				if (x < bbox[0]) x = bbox[0] + gt.snapSizeX;
				else if (x > bbox[2]) x = bbox[2] - gt.snapSizeX;
				if (y < bbox[3]) y = bbox[3] + gt.snapSizeY;
				else if (y > bbox[1]) y = bbox[1] - gt.snapSizeY;
			}

			point.setPosition(JXG.COORDS_BY_USER, [x, y]);
		}
	};

	gt.pairedPointDragRestricted = (e, point) => {
		gt.adjustDragPositionRestricted(e, point, point.paired_point);
		gt.updateObjects();
		gt.updateText();
	};

	gt.createPoint = (x, y, paired_point, restrict) => {
		const point = gt.board.create('point', [gt.snapRound(x, gt.snapSizeX), gt.snapRound(y, gt.snapSizeY)], {
			snapSizeX: gt.snapSizeX,
			snapSizeY: gt.snapSizeY,
			...gt.definingPointAttributes
		});
		point.setAttribute({ snapToGrid: true });
		point.on('down', () => (gt.board.containerObj.style.cursor = 'none'));
		point.on('up', () => (gt.board.containerObj.style.cursor = 'auto'));
		if (typeof paired_point !== 'undefined') {
			point.paired_point = paired_point;
			paired_point.paired_point = point;
			paired_point.on(
				'drag',
				restrict
					? (e) => gt.pairedPointDragRestricted(e, paired_point)
					: (e) => gt.pairedPointDrag(e, paired_point)
			);
			point.on(
				'drag',
				restrict ? (e) => gt.pairedPointDragRestricted(e, point) : (e) => gt.pairedPointDrag(e, point)
			);
		}
		return point;
	};

	gt.updateObjects = () => {
		gt.graphedObjs.forEach((obj) => obj.update());
		gt.staticObjs.forEach((obj) => obj.update());
	};

	// Generic graph object class from which all the specific graph objects derive.
	class GraphObject {
		supportsSolidDash = true;

		constructor(jsxGraphObject) {
			this.baseObj = jsxGraphObject;
			this.definingPts = [];
			// This is used to cache the last focused point for this object.  If focus is
			// returned by a pointer event then this point will be refocused.
			this.focusPoint = null;
		}

		handleKeyEvent(/* e, el */) {}

		blur() {
			this.focused = false;
			this.definingPts.forEach((obj) => obj.setAttribute({ visible: false }));
			this.baseObj.setAttribute({ strokeColor: gt.color.curve, strokeWidth: 2 });

			gt.updateHelp();
		}

		focus() {
			this.focused = true;
			this.definingPts.forEach((obj) => obj.setAttribute({ visible: true }));
			this.baseObj.setAttribute({ strokeColor: gt.color.focusCurve, strokeWidth: 3 });

			// Focus the currently set point of focus for this object.
			this.focusPoint?.rendNode.focus();

			gt.drawSolid = this.baseObj.getAttribute('dash') == 0;
			if (gt.solidButton) gt.solidButton.disabled = gt.drawSolid;
			if (gt.dashedButton) gt.dashedButton.disabled = !gt.drawSolid;

			gt.updateHelp();
		}

		isEventTarget(e) {
			if (this.baseObj.rendNode === e.target) return true;
			return this.definingPts.some((point) => point.rendNode === e.target);
		}

		update() {}

		fillCmp(/* point */) {
			return 1;
		}

		remove() {
			this.definingPts.forEach((point) => gt.board.removeObject(point));
			gt.board.removeObject(this.baseObj);
		}

		setSolid(solid) {
			this.baseObj.setAttribute({ dash: solid ? 0 : 2 });
		}

		stringify() {
			return '';
		}
		id() {
			return this.baseObj.id;
		}
		on(e, handler, context) {
			this.baseObj.on(e, handler, context);
		}
		off(e, handler) {
			this.baseObj.off(e, handler);
		}
		onResize() {}

		updateTextCoords(coords) {
			return !this.definingPts.every((point) => {
				if (point.hasPoint(coords.scrCoords[1], coords.scrCoords[2])) {
					gt.setTextCoords(point.X(), point.Y());
					return false;
				}
				return true;
			});
		}

		static restore(string) {
			const data = string.match(/^(.*?),(.*)/);
			if (data.length < 3) return false;
			let obj = false;
			Object.keys(gt.graphObjectTypes).every((type) => {
				if (data[1] == gt.graphObjectTypes[type].strId) {
					obj = gt.graphObjectTypes[type].restore(data[2]);
					return false;
				}
				return true;
			});
			if (obj !== false) obj.blur();
			return obj;
		}
	}

	// Line graph object
	class Line extends GraphObject {
		static strId = 'line';

		constructor(point1, point2, solid) {
			super(
				gt.board.create('line', [point1, point2], {
					fixed: true,
					highlight: false,
					strokeColor: gt.color.curve,
					dash: solid ? 0 : 2
				})
			);
			this.definingPts.push(point1, point2);
			this.focusPoint = point1;
		}

		stringify() {
			return [
				Line.strId,
				this.baseObj.getAttribute('dash') == 0 ? 'solid' : 'dashed',
				...this.definingPts.map(
					(point) => `(${gt.snapRound(point.X(), gt.snapSizeX)},${gt.snapRound(point.Y(), gt.snapSizeY)})`
				)
			].join(',');
		}

		fillCmp(point) {
			return gt.sign(JXG.Math.innerProduct(point, this.baseObj.stdform));
		}

		static restore(string) {
			let pointData = gt.pointRegexp.exec(string);
			const points = [];
			while (pointData) {
				points.push(pointData.slice(1, 3));
				pointData = gt.pointRegexp.exec(string);
			}
			if (points.length < 2) return false;
			const point1 = gt.createPoint(parseFloat(points[0][0]), parseFloat(points[0][1]));
			const point2 = gt.createPoint(parseFloat(points[1][0]), parseFloat(points[1][1]), point1);
			return new gt.graphObjectTypes.line(point1, point2, /solid/.test(string));
		}
	}

	// Circle graph object
	class Circle extends GraphObject {
		static strId = 'circle';

		constructor(center, point, solid) {
			super(
				gt.board.create('circle', [center, point], {
					fixed: true,
					highlight: false,
					strokeColor: gt.color.curve,
					dash: solid ? 0 : 2
				})
			);
			this.definingPts.push(center, point);
			this.focusPoint = center;

			// Redefine the circle's hasPoint method to return true if the center point has the given coordinates, so
			// that a pointer over the center point will give focus to the object with the center point activated.
			const circleHasPoint = this.baseObj.hasPoint.bind(this.baseObj);
			this.baseObj.hasPoint = (x, y) => circleHasPoint(x, y) || center.hasPoint(x, y);
		}

		stringify() {
			return [
				Circle.strId,
				this.baseObj.getAttribute('dash') == 0 ? 'solid' : 'dashed',
				...this.definingPts.map(
					(point) => `(${gt.snapRound(point.X(), gt.snapSizeX)},${gt.snapRound(point.Y(), gt.snapSizeY)})`
				)
			].join(',');
		}

		fillCmp(point) {
			return gt.sign(
				this.baseObj.stdform[3] * (point[1] * point[1] + point[2] * point[2]) +
					JXG.Math.innerProduct(point, this.baseObj.stdform)
			);
		}

		static restore(string) {
			let pointData = gt.pointRegexp.exec(string);
			const points = [];
			while (pointData) {
				points.push(pointData.slice(1, 3));
				pointData = gt.pointRegexp.exec(string);
			}
			if (points.length < 2) return false;
			const center = gt.createPoint(parseFloat(points[0][0]), parseFloat(points[0][1]));
			const point = gt.createPoint(parseFloat(points[1][0]), parseFloat(points[1][1]), center);
			return new gt.graphObjectTypes.circle(center, point, /solid/.test(string));
		}
	}

	// Parabola graph object.
	// The underlying jsxgraph object is really a curve.  The problem with the
	// jsxgraph parabola object is that it can not be created from the vertex
	// and a point on the graph of the parabola.
	const aVal = (vertex, point, vertical) =>
		vertical
			? (point.Y() - vertex.Y()) / Math.pow(point.X() - vertex.X(), 2)
			: (point.X() - vertex.X()) / Math.pow(point.Y() - vertex.Y(), 2);

	const createParabola = (vertex, point, vertical, solid, color) => {
		if (vertical)
			return gt.board.create(
				'curve',
				[
					// x and y coordinates of point on curve
					(x) => x,
					(x) => aVal(vertex, point, vertical) * Math.pow(x - vertex.X(), 2) + vertex.Y(),
					// domain minimum and maximum
					() => gt.board.getBoundingBox()[0],
					() => gt.board.getBoundingBox()[2]
				],
				{
					strokeWidth: 2,
					highlight: false,
					strokeColor: color ? color : gt.color.underConstruction,
					dash: solid ? 0 : 2
				}
			);
		else
			return gt.board.create(
				'curve',
				[
					// x and y coordinate of point on curve
					(x) => aVal(vertex, point, vertical) * Math.pow(x - vertex.Y(), 2) + vertex.X(),
					(x) => x,
					// domain minimum and maximum
					() => gt.board.getBoundingBox()[3],
					() => gt.board.getBoundingBox()[1]
				],
				{
					strokeWidth: 2,
					highlight: false,
					strokeColor: color ? color : gt.color.underConstruction,
					dash: solid ? 0 : 2
				}
			);
	};

	class Parabola extends GraphObject {
		static strId = 'parabola';

		constructor(vertex, point, vertical, solid) {
			super(createParabola(vertex, point, vertical, solid, gt.color.curve));
			this.definingPts.push(vertex, point);
			this.vertical = vertical;
			this.focusPoint = vertex;
		}

		stringify() {
			return [
				Parabola.strId,
				this.baseObj.getAttribute('dash') == 0 ? 'solid' : 'dashed',
				this.vertical ? 'vertical' : 'horizontal',
				...this.definingPts.map(
					(point) => `(${gt.snapRound(point.X(), gt.snapSizeX)},${gt.snapRound(point.Y(), gt.snapSizeY)})`
				)
			].join(',');
		}

		fillCmp(point) {
			if (this.vertical) return gt.sign(point[2] - this.baseObj.Y(point[1]));
			else return gt.sign(point[1] - this.baseObj.X(point[2]));
		}

		static restore(string) {
			let pointData = gt.pointRegexp.exec(string);
			const points = [];
			while (pointData) {
				points.push(pointData.slice(1, 3));
				pointData = gt.pointRegexp.exec(string);
			}
			if (points.length < 2) return false;
			const vertex = gt.createPoint(parseFloat(points[0][0]), parseFloat(points[0][1]));
			const point = gt.createPoint(parseFloat(points[1][0]), parseFloat(points[1][1]), vertex, true);
			return new gt.graphObjectTypes.parabola(vertex, point, /vertical/.test(string), /solid/.test(string));
		}
	}

	// Fill graph object
	class Fill extends GraphObject {
		static strId = 'fill';

		constructor(point) {
			super(point);
			this.supportsSolidDash = false;

			// Make the point invisible, but not with the jsxgraph visible attribute.  The icon will be shown instead.
			point.setAttribute({
				strokeOpacity: 0,
				highlightStrokeOpacity: 0,
				fillOpacity: 0,
				highlightFillOpacity: 0,
				fixed: gt.isStatic
			});
			this.definingPts.push(point);
			this.focusPoint = point;
			this.isAnswer = gt.graphingAnswers;
			this.focused = true;
			this.updateTimeout = 0;
			this.update();
			this.isStatic = gt.isStatic;

			point.rendNode.classList.add('hidden-fill-point');

			// The icon is what is actually shown. It is centered on the point which is the actual object.
			this.icon = gt.board.create(
				'image',
				[
					() => gt.fillIcon(this.focused ? gt.color.pointHighlight : gt.color.fill),
					[() => point.X() - 12 / gt.board.unitX, () => point.Y() - 12 / gt.board.unitY],
					[() => 24 / gt.board.unitX, () => 24 / gt.board.unitY]
				],
				{ withLabel: false, highlight: false, layer: 8, name: 'FillIcon', fixed: true }
			);

			if (!gt.isStatic) {
				this.on('drag', (e) => {
					gt.adjustDragPosition(e, this.baseObj);
					this.update();
					gt.updateText();
				});
			}
		}

		// The fill object has an invisible focus object.  So the focus/blur methods need to be overridden.
		blur() {
			this.focused = false;
			this.baseObj.setAttribute({ fixed: true });
			gt.board.update();
			gt.updateHelp();
		}

		focus() {
			this.focused = true;
			this.baseObj.setAttribute({ fixed: false });
			gt.board.update();
			this.baseObj.rendNode.focus();
			gt.updateHelp();
		}

		remove() {
			gt.board.removeObject(this.icon);
			if (this.fillObj) gt.board.removeObject(this.fillObj);
			super.remove();
		}

		update() {
			const updateReal = () => {
				this.updateTimeout = 0;
				if (this.fillObj) {
					gt.board.removeObject(this.fillObj);
					delete this.fillObj;
				}

				const centerPt = this.baseObj.coords.usrCoords;
				const allObjects = gt.graphedObjs.concat(gt.staticObjs);

				// Determine which side of each object needs to be shaded.  If the point
				// is on a graphed object, then don't fill.
				const a_vals = Array(allObjects.length);
				for (let i = 0; i < allObjects.length; ++i) {
					a_vals[i] = allObjects[i].fillCmp(centerPt);
					if (a_vals[i] == 0) return;
				}

				const canvas = document.createElement('canvas');
				canvas.width = gt.board.canvasWidth;
				canvas.height = gt.board.canvasHeight;
				const context = canvas.getContext('2d');
				const colorLayerData = context.getImageData(0, 0, canvas.width, canvas.height);

				const fillPixel = (pixelPos) => {
					colorLayerData.data[pixelPos] = Number('0x' + gt.color.fill.slice(1, 3));
					colorLayerData.data[pixelPos + 1] = Number('0x' + gt.color.fill.slice(3, 5));
					colorLayerData.data[pixelPos + 2] = Number('0x' + gt.color.fill.slice(5));
					colorLayerData.data[pixelPos + 3] = 255;
				};

				const isFillPixel = (x, y) => {
					const curPixel = [
						1.0,
						(x - gt.board.origin.scrCoords[1]) / gt.board.unitX,
						(gt.board.origin.scrCoords[2] - y) / gt.board.unitY
					];
					for (let i = 0; i < allObjects.length; ++i) {
						if (allObjects[i].fillCmp(curPixel) != a_vals[i]) return false;
					}
					return true;
				};

				for (let j = 0; j < canvas.width; ++j) {
					for (let k = 0; k < canvas.height; ++k) {
						if (isFillPixel(j, k)) fillPixel((k * canvas.width + j) * 4);
					}
				}

				context.putImageData(colorLayerData, 0, 0);
				const dataURL = canvas.toDataURL('image/png');
				canvas.remove();

				const boundingBox = gt.board.getBoundingBox();
				this.fillObj = gt.board.create(
					'image',
					[
						dataURL,
						[boundingBox[0], boundingBox[3]],
						[boundingBox[2] - boundingBox[0], boundingBox[1] - boundingBox[3]]
					],
					{ withLabel: false, highlight: false, fixed: true, layer: 0 }
				);
			};

			if (!('isStatic' in this) || (gt.isStatic && !gt.graphingAnswers) || this.isAnswer) {
				// The only time this happens is on initial construction or if the board is static.
				updateReal();
				return;
			} else if (this.isStatic) return;

			if (this.updateTimeout) clearTimeout(this.updateTimeout);
			this.updateTimeout = setTimeout(updateReal, 100);
		}

		stringify() {
			return [
				Fill.strId,
				`(${gt.snapRound(this.baseObj.X(), gt.snapSizeX)},${gt.snapRound(this.baseObj.Y(), gt.snapSizeY)})`
			].join(',');
		}

		static restore(string) {
			let pointData = gt.pointRegexp.exec(string);
			const points = [];
			while (pointData) {
				points.push(pointData.slice(1, 3));
				pointData = gt.pointRegexp.exec(string);
			}
			if (!points.length) return false;
			return new gt.graphObjectTypes.fill(gt.createPoint(parseFloat(points[0][0]), parseFloat(points[0][1])));
		}
	}

	gt.graphObjectTypes = {};
	gt.graphObjectTypes[Line.strId] = Line;
	gt.graphObjectTypes[Parabola.strId] = Parabola;
	gt.graphObjectTypes[Circle.strId] = Circle;
	gt.graphObjectTypes[Fill.strId] = Fill;

	// Load any custom graph objects.
	if ('customGraphObjects' in options) {
		Object.keys(options.customGraphObjects).forEach((name) => {
			const graphObject = options.customGraphObjects[name];
			const parentObject =
				'parent' in graphObject
					? graphObject.parent
						? gt.graphObjectTypes[graphObject.parent]
						: null
					: GraphObject;

			const customGraphObject = class extends parentObject {
				static strId = name;

				constructor(...args) {
					if (parentObject) {
						if ('preInit' in graphObject) super(graphObject.preInit.apply(null, [gt, ...args]));
						else super(...args);

						if ('postInit' in graphObject) graphObject.postInit.apply(this, [gt, ...args]);
					} else {
						const that = Object.create(new.target.prototype);
						// The preInit method is required if not deriving from another class.  It is essentially the
						// constructor in this case.  Furthermore, there is no need for a postInit method as everything
						// can be done in the preInit method.
						graphObject.preInit.apply(that, [gt, ...args]);
						return that;
					}
				}

				handleKeyEvent(e, el) {
					if ('handleKeyEvent' in graphObject) graphObject.handleKeyEvent.call(this, gt, e, el);
					else if (parentObject) super.handleKeyEvent(e, el);
				}

				blur() {
					if ((!('blur' in graphObject) || graphObject.blur.call(this, gt)) && parentObject) super.blur();
				}

				focus() {
					if ((!('focus' in graphObject) || graphObject.focus.call(this, gt)) && parentObject) super.focus();
				}

				isEventTarget(e) {
					if ('isEventTarget' in graphObject) return graphObject.isEventTarget.call(this, gt, e);
					else if (parentObject) return super.isEventTarget(e);
					return false;
				}

				update() {
					if ('update' in graphObject) graphObject.update.call(this, gt);
					else if (parentObject) super.update();
				}

				onResize() {
					if ('onResize' in graphObject) graphObject.onResize.call(this, gt);
					else if (parentObject) super.onResize();
				}

				updateTextCoords(coords) {
					if ('updateTextCoords' in graphObject) return graphObject.updateTextCoords.call(this, gt, coords);
					else if (parentObject) return super.updateTextCoords(coords);
					return false;
				}

				fillCmp(point) {
					if ('fillCmp' in graphObject) return graphObject.fillCmp.call(this, gt, point);
					else if (parentObject) return super.fillCmp(point);
					return 1;
				}

				remove() {
					if ('remove' in graphObject) graphObject.remove.call(this, gt);
					if (parentObject) super.remove();
				}

				setSolid(solid) {
					if ('setSolid' in graphObject) graphObject.setSolid.call(this, gt, solid);
					else if (parentObject) super.setSolid(solid);
				}

				on(e, handler, context) {
					if ('on' in graphObject) graphObject.on.call(this, e, handler, context);
					else if (parentObject) super.on(e, handler, context);
				}

				off(e, handler) {
					if ('off' in graphObject) graphObject.off.call(this, e, handler);
					else if (parentObject) super.off(e, handler);
				}

				stringify() {
					if ('stringify' in graphObject)
						return [customGraphObject.strId, graphObject.stringify.call(this, gt)].join(',');
					else if (parentObject) return super.stringify();
					return '';
				}

				static restore(string) {
					if ('restore' in graphObject) return graphObject.restore.call(this, gt, string);
					else if (parentObject) return super.restore(string);
					return false;
				}
			};

			// These are methods that must be called with a class instance (as in this.method(...args)).
			if ('classMethods' in graphObject) {
				for (const method of Object.keys(graphObject.classMethods)) {
					customGraphObject.prototype[method] = function (...args) {
						return graphObject.classMethods[method].call(this, gt, ...args);
					};
				}
			}

			// These are static class methods.
			if ('helperMethods' in graphObject) {
				Object.keys(graphObject.helperMethods).forEach((method) => {
					customGraphObject[method] = function (...args) {
						return graphObject.helperMethods[method].apply(this, [gt, ...args]);
					};
				});
			}

			gt.graphObjectTypes[customGraphObject.strId] = customGraphObject;
		});
	}

	// Generic tool class from which all the graphing tools derive.  Most of the methods, if overridden, must call the
	// corresponding generic method.  At this point the handleKeyEvent and updateHighlights methods are the ones that
	// this doesn't need to be done with.
	class GenericTool {
		constructor(container, name, tooltip) {
			const div = document.createElement('div');
			div.classList.add('gt-button-div');
			this.button = document.createElement('button');
			this.button.type = 'button';
			this.button.classList.add('gt-button', 'gt-tool-button', `gt-${name}-tool`);
			this.button.setAttribute('aria-label', tooltip);
			this.button.addEventListener('click', () => this.activate());
			this.button.addEventListener('pointerover', () => gt.setMessageText(tooltip));
			this.button.addEventListener('pointerout', () => gt.updateHelp());
			this.button.addEventListener('focus', () => gt.setMessageText(tooltip));
			this.button.addEventListener('blur', () => gt.updateHelp());
			div.append(this.button);
			container.append(div);
			this.hlObjs = {};
		}

		activate() {
			gt.activeTool?.deactivate();
			gt.activeTool = this;
			if (!(this instanceof SelectTool)) gt.board.containerObj.focus();
			this.button.disabled = true;
			gt.updateHelp();
		}

		finish() {
			gt.updateObjects();
			gt.updateText();
			gt.board.update();
			gt.selectTool.activate();
		}

		handleKeyEvent(/* e: KeyboardEvent */) {}

		updateHighlights(/* e: MouseEvent | KeyboardEvent | JXG.Coords | undefined */) {
			return false;
		}

		removeHighlights() {
			for (const obj in this.hlObjs) {
				gt.board.removeObject(this.hlObjs[obj]);
				delete this.hlObjs[obj];
			}
		}

		deactivate() {
			this.button.disabled = false;
			this.removeHighlights();
		}
	}

	// Select tool
	class SelectTool extends GenericTool {
		constructor(container) {
			super(container, 'select', 'Selection Tool: Select a graphed object to modify.');
		}

		helpText() {
			if (gt.activeTool === this) {
				return gt.graphedObjs.length
					? 'Make changes to the selected object, or select a new tool (Shift-N) to graph another object.'
					: 'Select a new tool (Shift-N) to graph an object.';
			}
			return '';
		}

		activate(initialize) {
			// Cache the currently selected object to re-select after the GenericTool
			// activate method de-selects it.
			const selectedObj = gt.selectedObj;
			super.activate();
			gt.selectedObj = selectedObj;

			// Select the object that was last active if there is one.
			// If not then select the first graphed object if there is one.
			if (!initialize && !gt.selectedObj) {
				if (this.lastSelected) gt.selectedObj = this.lastSelected;
				else if (gt.graphedObjs.length) gt.selectedObj = gt.graphedObjs[0];
			}

			delete this.lastSelected;

			if (gt.selectedObj) {
				// First focus the board, and then focus the currently select object.
				gt.board.containerObj.focus();
				gt.selectedObj.focus();
			}
			gt.updateUI();

			// This handles pointer selection of an object.
			for (const [index, obj] of gt.graphedObjs.entries()) {
				obj.selectionChangedHandler = (e) => {
					const coords = gt.getMouseCoords(e);

					// Determine if another object or one of its defining points is the actual target of this event.
					// This can happen if the defining point of another object is on this object and neither has focus.
					const otherIsTarget = gt.graphedObjs.some((otherObj) => {
						if (otherObj.id() === obj.id()) return false;
						return otherObj.isEventTarget(e);
					});

					// Check to see if one of the defining points of this object has the pointer.  If so set that point
					// as the focus point.  However, if some other object is the target then don't focus this object.
					// This is most important if a fill object is the target.  In that case the focus slips through to
					// the object below it.  Note that the actual focusing of the point needs to be delayed until it is
					// determined that this object either has focus or is will take focus.
					let focusPoint = null;
					for (const point of obj.definingPts) {
						if (point.hasPoint(coords.scrCoords[1], coords.scrCoords[2])) {
							obj.focusPoint = point;
							if (otherIsTarget) return;
							focusPoint = point;
							break;
						}
					}

					let lastSelected;
					if (gt.selectedObj) {
						if (gt.selectedObj.id() != obj.id()) {
							// Don't allow the selection of a new object if the pointer
							// is in the vicinity of one of the currently selected
							// object's defining points.
							for (const point of gt.selectedObj.definingPts) {
								if (
									point.X() == gt.snapRound(coords.usrCoords[1], gt.snapSizeX) &&
									point.Y() == gt.snapRound(coords.usrCoords[2], gt.snapSizeY)
								)
									return;
							}
							lastSelected = gt.selectedObj;
						} else {
							focusPoint?.rendNode.focus();
							return;
						}
					}

					focusPoint?.rendNode.focus();
					gt.selectedObj = obj;
					gt.selectedObj.focus();
					lastSelected?.blur();
				};
				obj.on('down', obj.selectionChangedHandler);

				// This changes the selection on tab or shift-tab ensures that a natural tabIndex order is followed for
				// the objects from first graphed to last.
				obj.definingPts.forEach((point, pIndex, a) => {
					// If this is the first or last defining point of an object, then attach a keydown handler that will
					// focus the previous or next object when shift-tab or tab is pressed.
					if (pIndex === 0 || pIndex === a.length - 1) {
						point.focusOutHandler = (e) => {
							if (
								e.key !== 'Tab' ||
								(index === 0 && e.shiftKey) ||
								(index === gt.graphedObjs.length - 1 && !e.shiftKey) ||
								(a.length > 1 &&
									((pIndex === 0 && !e.shiftKey) || (pIndex === a.length - 1 && e.shiftKey)))
							)
								return;

							e.preventDefault();
							e.stopPropagation();

							if (e.shiftKey) {
								gt.selectedObj = gt.graphedObjs[index - 1];
								gt.selectedObj.focusPoint =
									gt.selectedObj.definingPts[gt.selectedObj.definingPts.length - 1];
								gt.selectedObj.focus();
							} else {
								gt.selectedObj = gt.graphedObjs[index + 1];
								gt.selectedObj.focusPoint = gt.selectedObj.definingPts[0];
								gt.selectedObj.focus();
							}

							obj.blur();
						};
						point.rendNode.addEventListener('keydown', point.focusOutHandler);
					}

					// Attach a focusin handler to all points to update the coordinates display.
					point.focusInHandler = () => gt.setTextCoords(point.X(), point.Y());
					point.rendNode.addEventListener('focusin', point.focusInHandler);
				});
			}
		}

		deactivate() {
			this.lastSelected = gt.selectedObj;

			for (const obj of gt.graphedObjs) {
				obj.off('down', obj.selectionChangedHandler);
				delete obj.selectionChangedHandler;

				obj.definingPts
					.filter((_p, i, a) => i === 0 || i === a.length - 1)
					.forEach((point) => {
						point.rendNode.removeEventListener('keydown', point.focusOutHandler);
						point.rendNode.removeEventListener('focusin', point.focusInHandler);
						delete point.focusOutHandler;
					});
			}

			gt.selectedObj?.blur();
			delete gt.selectedObj;
			gt.updateUI();

			super.deactivate();
		}
	}

	// Line graphing tool
	class LineTool extends GenericTool {
		constructor(container, iconName, tooltip) {
			super(container, iconName ? iconName : 'line', tooltip ? tooltip : 'Line Tool: Graph a line.');
			this.supportsSolidDash = true;
		}

		handleKeyEvent(e) {
			if (!this.hlObjs.hl_point || !gt.board.containerObj.contains(document.activeElement)) return;

			if (e.key === 'Enter' || e.key === ' ') {
				e.preventDefault();
				e.stopPropagation();

				if (this.point1) this.phase2(this.hlObjs.hl_point.coords.usrCoords);
				else this.phase1(this.hlObjs.hl_point.coords.usrCoords);
			}
		}

		updateHighlights(e) {
			this.hlObjs.hl_line?.setAttribute({ dash: gt.drawSolid ? 0 : 2 });
			this.hlObjs.hl_point?.rendNode.focus();

			let coords;
			if (e instanceof MouseEvent && e.type === 'pointermove') {
				coords = gt.getMouseCoords(e);
				this.hlObjs.hl_point?.setPosition(JXG.COORDS_BY_USER, [coords.usrCoords[1], coords.usrCoords[2]]);
			} else if (e instanceof KeyboardEvent && e.type === 'keydown') {
				coords = this.hlObjs.hl_point.coords;
			} else if (e instanceof JXG.Coords) {
				coords = e;
				this.hlObjs.hl_point?.setPosition(JXG.COORDS_BY_USER, [coords.usrCoords[1], coords.usrCoords[2]]);
			} else return false;

			if (!this.hlObjs.hl_point) {
				this.hlObjs.hl_point = gt.board.create('point', [coords.usrCoords[1], coords.usrCoords[2]], {
					size: 2,
					color: gt.color.underConstruction,
					snapToGrid: true,
					highlight: false,
					snapSizeX: gt.snapSizeX,
					snapSizeY: gt.snapSizeY,
					withLabel: false
				});
				this.hlObjs.hl_point.rendNode.focus();
			}

			// Make sure the highlight point is not moved off the board or on the other point.
			if (e instanceof Event) gt.adjustDragPosition(e, this.hlObjs.hl_point, this.point1);

			if (this.point1 && !this.hlObjs.hl_line) {
				this.hlObjs.hl_line = gt.board.create('line', [this.point1, this.hlObjs.hl_point], {
					fixed: true,
					strokeColor: gt.color.underConstruction,
					highlight: false,
					dash: gt.drawSolid ? 0 : 2
				});
			}

			gt.setTextCoords(this.hlObjs.hl_point.X(), this.hlObjs.hl_point.Y());
			gt.board.update();
			return true;
		}

		// If graphing is interupted by pressing escape or the graph tool losing focus,
		// then clean up whatever has been done so far and deactivate the tool.
		deactivate() {
			delete this.helpText;
			gt.board.off('up');
			if (this.point1) gt.board.removeObject(this.point1);
			delete this.point1;
			gt.board.containerObj.style.cursor = 'auto';
			super.deactivate();
		}

		activate() {
			super.activate();
			gt.board.containerObj.style.cursor = 'none';

			// Draw a highlight point on the board.
			this.updateHighlights(new JXG.Coords(JXG.COORDS_BY_USER, [0, 0], gt.board));

			this.helpText = 'Plot two points on the line.';
			gt.updateHelp();

			// Wait for the user to select the first point.
			gt.board.on('up', (e) => this.phase1(gt.getMouseCoords(e).usrCoords));
		}

		// In phase1 the user has selected a point.  If that point is on the board, then make
		// that the first point for the line, and set up phase2.
		phase1(coords) {
			// Don't allow the point to be created off the board.
			if (!gt.boardHasPoint(coords[1], coords[2])) return;

			gt.board.off('up');

			this.point1 = gt.board.create('point', [coords[1], coords[2]], {
				size: 2,
				withLabel: false,
				highlight: false,
				snapToGrid: true,
				snapSizeX: gt.snapSizeX,
				snapSizeY: gt.snapSizeY
			});
			this.point1.setAttribute({ fixed: true });

			// Get a new x coordinate that is to the right, unless that is off the board.
			// In that case go left instead.
			let newX = this.point1.X() + gt.snapSizeX;
			if (newX > gt.board.getBoundingBox()[2]) newX = this.point1.X() - gt.snapSizeX;

			this.updateHighlights(new JXG.Coords(JXG.COORDS_BY_USER, [newX, this.point1.Y()], gt.board));

			this.helpText = 'Plot one more point on the line.';
			gt.updateHelp();

			gt.board.on('up', (e) => this.phase2(gt.getMouseCoords(e).usrCoords));

			gt.board.update();
		}

		// In phase2 the user has selected a second point.  If that point is on the board
		// and is not the same as the first point, then finalize the line.
		phase2(coords) {
			// Don't allow the second point to be created on top of the first or off the board
			if (
				(this.point1.X() == gt.snapRound(coords[1], gt.snapSizeX) &&
					this.point1.Y() == gt.snapRound(coords[2], gt.snapSizeY)) ||
				!gt.boardHasPoint(coords[1], coords[2])
			)
				return;

			gt.board.off('up');

			this.point1.setAttribute(gt.definingPointAttributes);
			this.point1.on('down', () => (gt.board.containerObj.style.cursor = 'none'));
			this.point1.on('up', () => (gt.board.containerObj.style.cursor = 'auto'));

			const point2 = gt.createPoint(coords[1], coords[2], this.point1);
			gt.selectedObj = new gt.graphObjectTypes.line(this.point1, point2, gt.drawSolid);
			gt.selectedObj.focusPoint = point2;
			gt.graphedObjs.push(gt.selectedObj);
			delete this.point1;

			this.finish();
		}
	}

	// Circle graphing tool
	class CircleTool extends GenericTool {
		constructor(container, iconName, tooltip) {
			super(container, iconName ? iconName : 'circle', tooltip ? tooltip : 'Circle Tool: Graph a circle.');
			this.supportsSolidDash = true;
		}

		handleKeyEvent(e) {
			if (!this.hlObjs.hl_point || !gt.board.containerObj.contains(document.activeElement)) return;

			if (e.key === 'Enter' || e.key === ' ') {
				e.preventDefault();
				e.stopPropagation();

				if (this.center) this.phase2(this.hlObjs.hl_point.coords.usrCoords);
				else this.phase1(this.hlObjs.hl_point.coords.usrCoords);
			}
		}

		updateHighlights(e) {
			this.hlObjs.hl_circle?.setAttribute({ dash: gt.drawSolid ? 0 : 2 });
			this.hlObjs.hl_point?.rendNode.focus();

			let coords;
			if (e instanceof MouseEvent && e.type === 'pointermove') {
				coords = gt.getMouseCoords(e);
				this.hlObjs.hl_point?.setPosition(JXG.COORDS_BY_USER, [coords.usrCoords[1], coords.usrCoords[2]]);
			} else if (e instanceof KeyboardEvent && e.type === 'keydown') {
				coords = this.hlObjs.hl_point.coords;
			} else if (e instanceof JXG.Coords) {
				coords = e;
				this.hlObjs.hl_point?.setPosition(JXG.COORDS_BY_USER, [coords.usrCoords[1], coords.usrCoords[2]]);
			} else return false;

			if (!this.hlObjs.hl_point) {
				this.hlObjs.hl_point = gt.board.create('point', [coords.usrCoords[1], coords.usrCoords[2]], {
					size: 2,
					color: gt.color.underConstruction,
					snapToGrid: true,
					highlight: false,
					snapSizeX: gt.snapSizeX,
					snapSizeY: gt.snapSizeY,
					withLabel: false
				});
				this.hlObjs.hl_point.rendNode.focus();
			}

			// Make sure the highlight point is not moved off the board or on the center.
			if (e instanceof Event) gt.adjustDragPosition(e, this.hlObjs.hl_point, this.center);

			if (this.center && !this.hlObjs.hl_circle) {
				this.hlObjs.hl_circle = gt.board.create('circle', [this.center, this.hlObjs.hl_point], {
					fixed: true,
					strokeColor: gt.color.underConstruction,
					highlight: false,
					dash: gt.drawSolid ? 0 : 2
				});
			}

			gt.setTextCoords(this.hlObjs.hl_point.X(), this.hlObjs.hl_point.Y());
			gt.board.update();
			return true;
		}

		deactivate() {
			delete this.helpText;
			gt.board.off('up');
			if (this.center) gt.board.removeObject(this.center);
			delete this.center;
			gt.board.containerObj.style.cursor = 'auto';
			super.deactivate();
		}

		activate() {
			super.activate();
			gt.board.containerObj.style.cursor = 'none';

			// Draw a highlight point on the board.
			this.updateHighlights(new JXG.Coords(JXG.COORDS_BY_USER, [0, 0], gt.board));

			this.helpText = 'Plot the center of the circle.';
			gt.updateHelp();

			gt.board.on('up', (e) => this.phase1(gt.getMouseCoords(e).usrCoords));
		}

		// In phase1 the user has selected a point.  If that point is on the board, then make
		// that the center of the circle, and set up phase2.
		phase1(coords) {
			// Don't allow the point to be created off the board.
			if (!gt.boardHasPoint(coords[1], coords[2])) return;
			gt.board.off('up');

			this.center = gt.board.create('point', [coords[1], coords[2]], {
				size: 2,
				withLabel: false,
				highlight: false,
				snapToGrid: true,
				snapSizeX: gt.snapSizeX,
				snapSizeY: gt.snapSizeY
			});
			this.center.setAttribute({ fixed: true });

			// Get a new x coordinate that is to the right, unless that is off the board.
			// In that case go left instead.
			let newX = this.center.X() + gt.snapSizeX;
			if (newX > gt.board.getBoundingBox()[2]) newX = this.center.X() - gt.snapSizeX;

			this.updateHighlights(new JXG.Coords(JXG.COORDS_BY_USER, [newX, this.center.Y()], gt.board));

			this.helpText = 'Plot a point on the circle.';
			gt.updateHelp();

			gt.board.on('up', (e) => this.phase2(gt.getMouseCoords(e).usrCoords));

			gt.board.update();
		}

		// In phase2 the user has selected a second point.  If that point is on the board
		// and is not the same as the center, then finalize the circle.
		phase2(coords) {
			// Don't allow the second point to be created on top of the center or off the board
			if (
				(this.center.X() == gt.snapRound(coords[1], gt.snapSizeX) &&
					this.center.Y() == gt.snapRound(coords[2], gt.snapSizeY)) ||
				!gt.boardHasPoint(coords[1], coords[2])
			)
				return;

			gt.board.off('up');

			this.center.setAttribute(gt.definingPointAttributes);
			this.center.on('down', () => (gt.board.containerObj.style.cursor = 'none'));
			this.center.on('up', () => (gt.board.containerObj.style.cursor = 'auto'));

			const point = gt.createPoint(coords[1], coords[2], this.center);
			gt.selectedObj = new gt.graphObjectTypes.circle(this.center, point, gt.drawSolid);
			gt.selectedObj.focusPoint = point;
			gt.graphedObjs.push(gt.selectedObj);
			delete this.center;

			this.finish();
		}
	}

	// Parabola graphing tool
	class ParabolaTool extends GenericTool {
		constructor(container, vertical, iconName, tooltip) {
			super(
				container,
				iconName ? iconName : vertical ? 'vertical-parabola' : 'horizontal-parabola',
				tooltip
					? tooltip
					: vertical
						? 'Vertical Parabola Tool: Graph a vertical parabola.'
						: 'Horizontal Parabola Tool: Graph an horizontal parabola.'
			);
			this.vertical = vertical;
			this.supportsSolidDash = true;
		}

		handleKeyEvent(e) {
			if (!this.hlObjs.hl_point || !gt.board.containerObj.contains(document.activeElement)) return;

			if (e.key === 'Enter' || e.key === ' ') {
				e.preventDefault();
				e.stopPropagation();

				if (this.vertex) this.phase2(this.hlObjs.hl_point.coords.usrCoords);
				else this.phase1(this.hlObjs.hl_point.coords.usrCoords);
			}
		}

		updateHighlights(e) {
			this.hlObjs.hl_parabola?.setAttribute({ dash: gt.drawSolid ? 0 : 2 });
			this.hlObjs.hl_point?.rendNode.focus();

			let coords;
			if (e instanceof MouseEvent && e.type === 'pointermove') {
				coords = gt.getMouseCoords(e);
				this.hlObjs.hl_point?.setPosition(JXG.COORDS_BY_USER, [coords.usrCoords[1], coords.usrCoords[2]]);
			} else if (e instanceof KeyboardEvent && e.type === 'keydown') {
				coords = this.hlObjs.hl_point.coords;
			} else if (e instanceof JXG.Coords) {
				coords = e;
				this.hlObjs.hl_point?.setPosition(JXG.COORDS_BY_USER, [coords.usrCoords[1], coords.usrCoords[2]]);
			} else return false;

			if (!this.hlObjs.hl_point) {
				this.hlObjs.hl_point = gt.board.create('point', [coords.usrCoords[1], coords.usrCoords[2]], {
					size: 2,
					color: gt.color.underConstruction,
					snapToGrid: true,
					snapSizeX: gt.snapSizeX,
					snapSizeY: gt.snapSizeY,
					highlight: false,
					withLabel: false
				});
				this.hlObjs.hl_point.rendNode.focus();
			}

			// Make sure the highlight point is not moved off the board or
			// onto the same horizontal or vertical line as the vertex.
			if (e instanceof Event) gt.adjustDragPositionRestricted(e, this.hlObjs.hl_point, this.vertex);

			if (this.vertex && !this.hlObjs.hl_parabola) {
				this.hlObjs.hl_parabola = createParabola(
					this.vertex,
					this.hlObjs.hl_point,
					this.vertical,
					gt.drawSolid,
					gt.color.underConstruction
				);
			}

			gt.setTextCoords(this.hlObjs.hl_point.X(), this.hlObjs.hl_point.Y());
			gt.board.update();
			return true;
		}

		deactivate() {
			delete this.helpText;
			gt.board.off('up');
			if (this.vertex) gt.board.removeObject(this.vertex);
			delete this.vertex;
			gt.board.containerObj.style.cursor = 'auto';
			super.deactivate();
		}

		activate() {
			super.activate();
			gt.board.containerObj.style.cursor = 'none';

			// Draw a highlight point on the board.
			this.updateHighlights(new JXG.Coords(JXG.COORDS_BY_USER, [0, 0], gt.board));

			this.helpText = 'Plot the vertex of the parabola.';
			gt.updateHelp();

			gt.board.on('up', (e) => this.phase1(gt.getMouseCoords(e).usrCoords));
		}

		phase1(coords) {
			// Don't allow the point to be created off the board.
			if (!gt.boardHasPoint(coords[1], coords[2])) return;

			gt.board.off('up');

			this.vertex = gt.board.create('point', [coords[1], coords[2]], {
				size: 2,
				withLabel: false,
				highlight: false,
				snapToGrid: true,
				snapSizeX: gt.snapSizeX,
				snapSizeY: gt.snapSizeY
			});
			this.vertex.setAttribute({ fixed: true });

			// Get a new x coordinate that is to the right, unless that is off the board.
			// In that case go left instead.
			let newX = this.vertex.X() + gt.snapSizeX;
			if (newX > gt.board.getBoundingBox()[2]) newX = this.vertex.X() - gt.snapSizeX;

			// Get a new y coordinate that is above, unless that is off the board.
			// In that case go below instead.
			let newY = this.vertex.Y() + gt.snapSizeY;
			if (newY > gt.board.getBoundingBox()[1]) newY = this.vertex.Y() - gt.snapSizeY;

			this.updateHighlights(new JXG.Coords(JXG.COORDS_BY_USER, [newX, newY], gt.board));

			this.helpText = 'Plot another point on the parabola.';
			gt.updateHelp();

			gt.board.on('up', (e) => this.phase2(gt.getMouseCoords(e).usrCoords));

			gt.board.update();
		}

		phase2(coords) {
			// Don't allow the second point to be created on the same
			// horizontal or vertical line as the vertex or off the board.
			if (
				this.vertex.X() == gt.snapRound(coords[1], gt.snapSizeX) ||
				this.vertex.Y() == gt.snapRound(coords[2], gt.snapSizeY) ||
				!gt.boardHasPoint(coords[1], coords[2])
			)
				return;

			gt.board.off('up');

			this.vertex.setAttribute(gt.definingPointAttributes);
			this.vertex.on('down', () => (gt.board.containerObj.style.cursor = 'none'));
			this.vertex.on('up', () => (gt.board.containerObj.style.cursor = 'auto'));

			const point = gt.createPoint(coords[1], coords[2], this.vertex, true);
			gt.selectedObj = new gt.graphObjectTypes.parabola(this.vertex, point, this.vertical, gt.drawSolid);
			gt.selectedObj.focusPoint = point;
			gt.graphedObjs.push(gt.selectedObj);
			delete this.vertex;

			this.finish();
		}
	}

	class VerticalParabolaTool extends ParabolaTool {
		constructor(container, iconName, tooltip) {
			super(container, true, iconName, tooltip);
		}
	}

	class HorizontalParabolaTool extends ParabolaTool {
		constructor(container, iconName, tooltip) {
			super(container, false, iconName, tooltip);
		}
	}

	// Fill tool
	class FillTool extends GenericTool {
		constructor(container, iconName, tooltip) {
			super(
				container,
				iconName ? iconName : 'fill',
				tooltip ? tooltip : 'Region Shading Tool: Shade a region in the graph.'
			);
		}

		handleKeyEvent(e) {
			if (!this.hlObjs.hl_point || !gt.board.containerObj.contains(document.activeElement)) return;

			if (e.key === 'Enter' || e.key === ' ') {
				e.preventDefault();
				e.stopPropagation();

				this.phase1(this.hlObjs.hl_point.coords.usrCoords);
			}
		}

		updateHighlights(e) {
			this.hlObjs.hl_point?.rendNode.focus();

			let coords;
			if (e instanceof MouseEvent && e.type === 'pointermove') {
				coords = gt.getMouseCoords(e);
				this.hlObjs.hl_point?.setPosition(JXG.COORDS_BY_USER, [coords.usrCoords[1], coords.usrCoords[2]]);
			} else if (e instanceof KeyboardEvent && e.type === 'keydown') {
				coords = this.hlObjs.hl_point.coords;
			} else if (e instanceof JXG.Coords) {
				coords = e;
				this.hlObjs.hl_point?.setPosition(JXG.COORDS_BY_USER, [coords.usrCoords[1], coords.usrCoords[2]]);
			} else return false;

			if (!this.hlObjs.hl_point) {
				this.hlObjs.hl_point = gt.board.create('point', [coords.usrCoords[1], coords.usrCoords[2]], {
					size: 2,
					strokeColor: 'transparent',
					fillColor: 'transparent',
					strokeOpacity: 0,
					fillOpacity: 0,
					highlight: false,
					withLabel: false,
					snapToGrid: true,
					snapSizeX: gt.snapSizeX,
					snapSizeY: gt.snapSizeY
				});
				this.hlObjs.hl_point.rendNode.classList.add('hidden-fill-point');

				this.hlObjs.hl_icon = gt.board.create(
					'image',
					[
						gt.fillIcon(gt.color.fill),
						[
							() => this.hlObjs.hl_point.X() - 12 / gt.board.unitX,
							() => this.hlObjs.hl_point.Y() - 12 / gt.board.unitY
						],
						[() => 24 / gt.board.unitX, () => 24 / gt.board.unitY]
					],
					{ withLabel: false, highlight: false, fixed: true, layer: 8 }
				);

				this.hlObjs.hl_point.rendNode.focus();
			}

			// Make sure the point/icon is not moved off the board.
			if (e instanceof Event) gt.adjustDragPosition(e, this.hlObjs.hl_point);

			gt.setTextCoords(coords.usrCoords[1], coords.usrCoords[2]);
			gt.board.update();
			return true;
		}

		deactivate() {
			delete this.helpText;
			gt.board.off('up');
			gt.board.containerObj.style.cursor = 'auto';
			super.deactivate();
		}

		activate() {
			super.activate();
			gt.board.containerObj.style.cursor = 'none';

			// Draw a highlight point on the board.
			this.updateHighlights(new JXG.Coords(JXG.COORDS_BY_USER, [0, 0], gt.board));

			this.helpText = 'Choose a point in the region to be filled.';
			gt.updateHelp();

			gt.board.on('up', (e) => this.phase1(gt.getMouseCoords(e).usrCoords));
		}

		phase1(coords) {
			// Don't allow the fill to be created off the board
			if (!gt.boardHasPoint(coords[1], coords[2])) return;
			gt.board.off('up');

			gt.selectedObj = new gt.graphObjectTypes.fill(gt.createPoint(coords[1], coords[2]));
			gt.graphedObjs.push(gt.selectedObj);

			this.finish();
		}
	}

	// Draw objects solid or dashed. Makes the currently selected object (if
	// any) solid or dashed, and anything drawn while the tool is selected will
	// be drawn solid or dashed.
	gt.toggleSolidity = (e, drawSolid) => {
		e.preventDefault();
		e.stopPropagation();

		if (gt.selectedObj) {
			// Prevent the gt.board.containerObj focusin handler from moving focus to the last graphed object.
			gt.objectFocusSet = true;

			gt.selectedObj.setSolid(drawSolid);
			gt.updateText();
		}
		gt.drawSolid = drawSolid;

		gt.selectedObj?.focus();
		gt.activeTool?.updateHighlights();
		if (!gt.selectedObj && gt.activeTool === gt.selectTool) gt.board.containerObj.focus();

		if (gt.solidButton) gt.solidButton.disabled = drawSolid;
		if (gt.dashedButton) gt.dashedButton.disabled = !drawSolid;
	};

	class SolidDashTool {
		constructor(container) {
			const solidDashBox = document.createElement('div');
			const makeSolidButtonMessage = 'Make the selected object solid (s).';
			solidDashBox.classList.add('gt-tool-button-pair');
			// The default is to draw objects solid.  So the draw solid button is disabled by default.
			const solidButtonDiv = document.createElement('div');
			solidButtonDiv.classList.add('gt-button-div', 'gt-tool-button-pair-top');
			solidButtonDiv.addEventListener('pointerover', () => gt.setMessageText(makeSolidButtonMessage));
			solidButtonDiv.addEventListener('pointerout', () => gt.updateHelp());
			gt.solidButton = document.createElement('button');
			gt.solidButton.classList.add('gt-button', 'gt-tool-button', 'gt-solid-tool');
			gt.solidButton.type = 'button';
			gt.solidButton.setAttribute('aria-label', makeSolidButtonMessage);
			gt.solidButton.disabled = true;
			gt.solidButton.addEventListener('click', (e) => gt.toggleSolidity(e, true));
			gt.solidButton.addEventListener('focus', () => gt.setMessageText(makeSolidButtonMessage));
			gt.solidButton.addEventListener('blur', () => gt.updateHelp());
			solidButtonDiv.append(gt.solidButton);
			solidDashBox.append(solidButtonDiv);

			const dashedButtonDiv = document.createElement('div');
			const makeDashedButtonMessage = 'Make the selected object dashed (d).';
			dashedButtonDiv.classList.add('gt-button-div', 'gt-tool-button-pair-bottom');
			dashedButtonDiv.addEventListener('pointerover', () => gt.setMessageText(makeDashedButtonMessage));
			dashedButtonDiv.addEventListener('pointerout', () => gt.updateHelp());
			gt.dashedButton = document.createElement('button');
			gt.dashedButton.classList.add('gt-button', 'gt-tool-button', 'gt-dashed-tool');
			gt.dashedButton.type = 'button';
			gt.dashedButton.setAttribute('aria-label', makeDashedButtonMessage);
			gt.dashedButton.addEventListener('click', (e) => gt.toggleSolidity(e, false));
			gt.dashedButton.addEventListener('focus', () => gt.setMessageText(makeDashedButtonMessage));
			gt.dashedButton.addEventListener('blur', () => gt.updateHelp());
			dashedButtonDiv.append(gt.dashedButton);
			solidDashBox.append(dashedButtonDiv);
			container.append(solidDashBox);
		}

		handleKeyEvent(e) {
			if (e.key === 's') {
				// If 's' is pressed change to drawing solid.
				gt.toggleSolidity(e, true);
			} else if (e.key === 'd') {
				// If 'd' is pressed change to drawing dashed.
				gt.toggleSolidity(e, false);
			}
		}

		helpText() {
			return (gt.selectedObj && gt.selectedObj.supportsSolidDash) ||
				(gt.activeTool && gt.activeTool.supportsSolidDash)
				? 'Use the ' +
						'\\(\\rule[3px]{34px}{2px}\\) or ' +
						'\\(\\rule[3px]{3px}{2px}' +
						'\\hspace{4px}\\rule[3px]{4px}{2px}'.repeat(3) +
						'\\hspace{4px}\\rule[3px]{3px}{2px}\\)' +
						' button or type s or d to make the selected object solid or dashed.'
				: '';
		}
	}

	gt.toolTypes = {
		LineTool: LineTool,
		CircleTool: CircleTool,
		VerticalParabolaTool: VerticalParabolaTool,
		HorizontalParabolaTool: HorizontalParabolaTool,
		FillTool: FillTool,
		SolidDashTool: SolidDashTool
	};

	// Create the tools and html elements.
	const graphDiv = document.createElement('div');
	graphDiv.id = `${containerId}_graph`;
	graphDiv.classList.add('jxgbox', 'graphtool-graph');
	if (options.numberLine) graphDiv.classList.add('graphtool-number-line');
	gt.graphContainer.append(graphDiv);

	if (!gt.isStatic) {
		gt.buttonBox = document.createElement('div');
		gt.buttonBox.classList.add('gt-toolbar-container');
		gt.selectTool = new SelectTool(gt.buttonBox);

		// Load any custom tools.
		if ('customTools' in options) {
			Object.keys(options.customTools).forEach((tool) => {
				const toolObject = options.customTools[tool];
				const parentTool =
					'parent' in toolObject ? (toolObject.parent ? gt.toolTypes[toolObject.parent] : null) : GenericTool;
				const customTool = class extends parentTool {
					constructor(container) {
						if (parentTool) {
							super(container, toolObject.iconName, toolObject.tooltip);
							if ('initialize' in toolObject) toolObject.initialize.call(this, gt, container);
						} else {
							const that = Object.create(new.target.prototype);
							// The initialize method is required if not deriving from another class.  It is essentially
							// the constructor in this case.
							toolObject.initialize.call(that, gt, container);
							return that;
						}
					}

					handleKeyEvent(e) {
						if ('handleKeyEvent' in toolObject) toolObject.handleKeyEvent.call(this, gt, e);
						if (parentTool) super.handleKeyEvent(e);
					}

					activate() {
						if (parentTool) super.activate();
						if ('activate' in toolObject) toolObject.activate.call(this, gt);
					}

					deactivate() {
						if ('deactivate' in toolObject) toolObject.deactivate.call(this, gt);
						if (parentTool) super.deactivate();
					}

					updateHighlights(coords) {
						if ('updateHighlights' in toolObject) return toolObject.updateHighlights.call(this, gt, coords);
						if (parentTool) return super.updateHighlights(coords);
						return false;
					}

					removeHighlights() {
						if ('removeHighlights' in toolObject) toolObject.removeHighlights.call(this, gt);
						if (parentTool) super.removeHighlights();
					}
				};

				// These are methods that must be called with a class instance (as in this.method(...args)).
				if ('classMethods' in toolObject) {
					for (const method of Object.keys(toolObject.classMethods)) {
						customTool.prototype[method] = function (...args) {
							return toolObject.classMethods[method].call(this, gt, ...args);
						};
					}
				}

				// These are static class methods.
				if ('helperMethods' in toolObject) {
					Object.keys(toolObject.helperMethods).forEach((method) => {
						customTool[method] = function (...args) {
							return toolObject.helperMethods[method].apply(this, [gt, ...args]);
						};
					});
				}

				gt.toolTypes[tool] = customTool;
			});
		}

		gt.tools = [gt.selectTool];
		for (const tool of options.availableTools) {
			if (tool in gt.toolTypes) gt.tools.push(new gt.toolTypes[tool](gt.buttonBox));
			else console.log(`Unknown tool: ${tool}`);
		}

		gt.confirm = async (question, yesAction) => {
			const overlay = document.createElement('div');
			overlay.classList.add('gt-confirm-overlay');
			overlay.tabIndex = -1;

			const container = document.createElement('div');
			container.classList.add('gt-confirm');
			container.tabIndex = -1;

			const controller = new AbortController();
			gt.confirm.dispose = (e) => {
				controller.abort();
				delete gt.confirm.dispose;
				overlay.remove();
				container.remove();

				if (e.type !== 'focusout') {
					if (gt.selectedObj) gt.selectedObj.focus();
					else if (gt.graphedObjs.length) gt.board.containerObj.focus();
					else gt.buttonBox.querySelectorAll('.gt-button:not([disabled])')[0]?.focus();
				}

				gt.confirmationActive = false;

				gt.updateHelp();
			};
			overlay.addEventListener('pointerdown', gt.confirm.dispose, { signal: controller.signal });

			const questionElt = document.createElement('div');
			questionElt.textContent = question;

			const buttonContainer = document.createElement('div');
			buttonContainer.classList.add('gt-confirm-buttons');

			const yesButton = document.createElement('button');
			yesButton.type = 'button';
			yesButton.classList.add('gt-button', 'gt-text-button', 'gt-confirm-button');
			yesButton.textContent = 'Yes';
			yesButton.addEventListener(
				'click',
				(e) => {
					yesAction();
					gt.confirm.dispose(e);
				},
				{ signal: controller.signal }
			);

			const noButton = document.createElement('button');
			noButton.type = 'button';
			noButton.classList.add('gt-button', 'gt-text-button', 'gt-confirm-button');
			noButton.textContent = 'No';
			noButton.addEventListener('click', gt.confirm.dispose, { signal: controller.signal });

			buttonContainer.append(yesButton, noButton);

			container.append(questionElt, buttonContainer);

			await gt.setMessageContent(container, true);

			// Remove the confirmation if focus is shifted back into the graph tool.
			gt.buttonBox.addEventListener('focusin', gt.confirm.dispose, { signal: controller.signal });

			gt.graphContainer.append(overlay);
			container.focus();
		};

		gt.deleteSelected = () => {
			if (!gt.selectedObj) return;

			gt.confirm('Do you want to delete the selected object?', () => {
				const i = gt.graphedObjs.findIndex((obj) => obj.id() === gt.selectedObj.id());
				gt.graphedObjs[i].remove();
				gt.graphedObjs.splice(i, 1);

				if (i < gt.graphedObjs.length) gt.selectedObj = gt.graphedObjs[i];
				else if (gt.graphedObjs.length) gt.selectedObj = gt.graphedObjs[0];
				else delete gt.selectedObj;
				delete gt.selectTool.lastSelected;

				// Toggle the select tool so that the focus order event handlers are realigned.
				gt.selectTool.deactivate();
				gt.selectTool.activate();

				gt.updateObjects();
				gt.updateText();
			});
		};

		// Add a button to delete the selected object.
		const deleteButtonContainer = document.createElement('div');
		const deleteButtonMessage = 'Delete the selected object (Delete).';
		deleteButtonContainer.classList.add('gt-button-div');
		deleteButtonContainer.addEventListener('pointerover', () => gt.setMessageText(deleteButtonMessage));
		deleteButtonContainer.addEventListener('pointerout', () => gt.updateHelp());
		gt.deleteButton = document.createElement('button');
		gt.deleteButton.type = 'button';
		gt.deleteButton.classList.add('gt-button', 'gt-text-button');
		gt.deleteButton.textContent = 'Delete';
		gt.deleteButton.addEventListener('click', gt.deleteSelected);
		gt.deleteButton.addEventListener('focus', () => gt.setMessageText(deleteButtonMessage));
		gt.deleteButton.addEventListener('blur', () => gt.updateHelp());
		deleteButtonContainer.append(gt.deleteButton);
		gt.buttonBox.append(deleteButtonContainer);

		gt.clearAll = () => {
			if (gt.graphedObjs.length == 0) return;

			gt.confirm('Do you want to remove all graphed objects?', () => {
				gt.graphedObjs.forEach((obj) => obj.remove());
				gt.graphedObjs = [];
				delete gt.selectedObj;
				delete gt.selectTool.lastSelected;
				gt.selectTool.activate();
				gt.html_input.value = '';
			});
		};

		// Add a button to remove all graphed objects.
		const clearButtonContainer = document.createElement('div');
		const clearButtonMessage = 'Clear all objects from the graph (Ctrl-Delete).';
		clearButtonContainer.classList.add('gt-button-div');
		clearButtonContainer.addEventListener('pointerover', () => gt.setMessageText(clearButtonMessage));
		clearButtonContainer.addEventListener('pointerout', () => gt.updateHelp());
		gt.clearButton = document.createElement('button');
		gt.clearButton.type = 'button';
		gt.clearButton.classList.add('gt-button', 'gt-text-button');
		gt.clearButton.textContent = 'Clear';
		gt.clearButton.addEventListener('click', gt.clearAll);
		gt.clearButton.addEventListener('focus', () => gt.setMessageText(clearButtonMessage));
		gt.clearButton.addEventListener('blur', () => gt.updateHelp());
		clearButtonContainer.append(gt.clearButton);
		gt.buttonBox.append(clearButtonContainer);

		// Full screen mode handlers.
		const fullscreenScale = () => {
			gt.graphContainer.style.removeProperty('transform');

			const gtRect = gt.graphContainer.getBoundingClientRect();
			const fsRect = gt.graphContainer.parentElement.getBoundingClientRect();

			const scale =
				gtRect.height / gtRect.width < fsRect.height / fsRect.width
					? (fsRect.width * 0.95) / gtRect.width
					: (fsRect.height * 0.95) / gtRect.height;

			gt.graphContainer.style.transform = `matrix(${scale},0,0,${scale},0,${
				(fsRect.height - gtRect.height) * 0.5
			})`;

			// Update the jsxgraph css transforms so that mouse cursor position is reported correctly.
			gt.board.updateCSSTransforms();
		};

		let promiseSupported = false;

		const toggleFullscreen = () => {
			const wrap_node =
				document.getElementById(`gt-fullscreenwrap-${containerId}`) || document.createElement('div');

			if (!wrap_node.classList.contains('gt-fullscreenwrap')) {
				// When the graphtool container is taken out of the DOM and placed in the wrap node in fullscreen mode
				// the size of the page changes, and thus the current scroll position can change.  So save the current
				// scroll position so it can be restored when fullscreen mode is exited.
				wrap_node.currentScroll = { x: window.scrollX, y: window.scrollY };

				wrap_node.classList.add('gt-fullscreenwrap');
				wrap_node.id = `gt-fullscreenwrap-${containerId}`;
				gt.graphContainer.before(wrap_node);
				wrap_node.appendChild(gt.graphContainer);
			}

			if (document.fullscreenElement || document.webkitFullscreenElement) {
				document.exitFullscreen?.();
				document.webkitExitFullscreen?.();
			} else {
				wrap_node.requestFullscreen = wrap_node.requestFullscreen || wrap_node.webkitRequestFullscreen;
				if (wrap_node.requestFullscreen) {
					// Disable the jsxgraph resize observer.  It conflicts with the local resize observer.
					gt.board.stopResizeObserver();
					const fullscreenPromise = wrap_node.requestFullscreen();
					if (fullscreenPromise instanceof Promise) {
						promiseSupported = true;
						fullscreenPromise.then(fullscreenScale);
					}
					gt.resizeObserver = new ResizeObserver(fullscreenScale);
					gt.resizeObserver.observe(wrap_node);
					gt.resizeObserver.observe(gt.graphContainer);
				}
			}
		};

		// Add a button to switch to full screen mode.
		gt.fullScreenButton = document.createElement('button');
		let fullScreenButtonMessage = 'Switch to fullscreen.';
		gt.fullScreenButton.type = 'button';
		gt.fullScreenButton.classList.add('gt-button', 'gt-text-button');
		gt.fullScreenButton.textContent = 'Fullscreen';
		gt.fullScreenButton.addEventListener('click', () => toggleFullscreen());
		gt.fullScreenButton.addEventListener('pointerover', () => gt.setMessageText(fullScreenButtonMessage));
		gt.fullScreenButton.addEventListener('pointerout', () => gt.updateHelp());
		gt.fullScreenButton.addEventListener('focus', () => gt.setMessageText(fullScreenButtonMessage));
		gt.fullScreenButton.addEventListener('blur', () => gt.updateHelp());
		for (const eventType of ['fullscreenchange', 'webkitfullscreenchange']) {
			document.addEventListener(eventType, () => {
				const wrap_node = document.getElementById(`gt-fullscreenwrap-${containerId}`);
				if (!wrap_node) return;
				if (document.fullscreenElement === wrap_node || document.webkitFullscreenElement === wrap_node) {
					gt.fullScreenButton.textContent = 'Exit Fullscreen';
					fullScreenButtonMessage = 'Exit fullscreen.';
					if (!promiseSupported) fullscreenScale();
				} else {
					if (gt.resizeObserver) gt.resizeObserver.disconnect();
					delete gt.resizeObserver;
					wrap_node.replaceWith(gt.graphContainer);
					gt.graphContainer.style.removeProperty('transform');
					gt.board.updateCSSTransforms();
					// Give resize control back to jsxgraph.
					gt.board.startResizeObserver();
					if (wrap_node.currentScroll) {
						window.scroll({
							left: wrap_node.currentScroll.x,
							top: wrap_node.currentScroll.y,
							behavior: 'instant'
						});
					}
					gt.fullScreenButton.textContent = 'Fullscreen';
					fullScreenButtonMessage = 'Switch to fullscreen.';
				}
				gt.updateHelp();
			});
		}
		gt.buttonBox.append(gt.fullScreenButton);

		// Add a button to disable or enable help.
		gt.helpEnabled = localStorage.getItem('GraphToolHelpEnabled') !== 'false';
		gt.disableHelpButton = document.createElement('button');
		const disableHelpButtonMessage = 'Disable this help for all graphs.';
		gt.disableHelpButton.type = 'button';
		gt.disableHelpButton.classList.add('gt-button', 'gt-text-button', 'gt-disable-help-button');
		gt.disableHelpButton.textContent = gt.helpEnabled ? 'Disable Help' : 'Enable Help';
		const setHelpStatus = (enabled) => {
			gt.helpEnabled = enabled;
			if (enabled) {
				gt.disableHelpButton.textContent = 'Disable Help';
				gt.messageBox.classList.remove('gt-disabled-help');
				gt.updateHelp();
			} else {
				gt.disableHelpButton.textContent = 'Enable Help';
				gt.messageBox.classList.add('gt-disabled-help');
				gt.setMessageContent();
			}
		};
		gt.disableHelpButton.addEventListener('click', () => {
			setHelpStatus(!gt.helpEnabled);
			localStorage.setItem('GraphToolHelpEnabled', gt.helpEnabled);
			// Notify other graphs on the page that the help status has changed.
			for (const button of document.querySelectorAll('.gt-disable-help-button')) {
				if (button === gt.disableHelpButton) continue;
				button.dispatchEvent(new CustomEvent('gt.help.enable', { detail: { enabled: gt.helpEnabled } }));
			}
		});
		// If the enable/disable help button was activated on another graph, then act on the event it sent.
		gt.disableHelpButton.addEventListener('gt.help.enable', (e) => setHelpStatus(e.detail.enabled));
		gt.disableHelpButton.addEventListener('pointerover', () => gt.setMessageText(disableHelpButtonMessage));
		gt.disableHelpButton.addEventListener('pointerout', () => gt.updateHelp());
		gt.disableHelpButton.addEventListener('focus', () => gt.setMessageText(disableHelpButtonMessage));
		gt.disableHelpButton.addEventListener('blur', () => gt.updateHelp());
		gt.buttonBox.append(gt.disableHelpButton);

		gt.graphContainer.append(gt.buttonBox);

		gt.messageBox = document.createElement('div');
		gt.messageBox.classList.add('gt-message-box');
		if (!gt.helpEnabled) gt.messageBox.classList.add('gt-disabled-help');
		gt.messageBox.setAttribute('role', 'region');
		gt.messageBox.setAttribute('aria-live', 'polite');
		gt.graphContainer.append(gt.messageBox);
		gt.messageBox.addEventListener('keydown', (e) => {
			if (e.key === 'Escape') gt.confirm.dispose?.(e);
		});
	}

	setupBoard();

	// Restore data from previous attempts if available
	const restoreObjects = (data, objectsAreStatic, objectsAreAnswers) => {
		gt.board.suspendUpdate();
		const tmpIsStatic = gt.isStatic;
		gt.isStatic = objectsAreStatic;
		gt.graphingAnswers = objectsAreAnswers;
		const objectRegexp = /{(.*?)}/g;
		let objectData = objectRegexp.exec(data);
		while (objectData) {
			const obj = GraphObject.restore(objectData[1]);
			if (obj !== false) {
				if (objectsAreStatic) gt.staticObjs.push(obj);
				else gt.graphedObjs.push(obj);
			}
			objectData = objectRegexp.exec(data);
		}
		gt.updateObjects();
		gt.isStatic = tmpIsStatic;
		delete gt.graphingAnswers;
		gt.board.unsuspendUpdate();
	};

	if ('staticObjects' in options && typeof options.staticObjects === 'string' && options.staticObjects.length)
		restoreObjects(options.staticObjects, true);
	if ('answerObjects' in options && typeof options.answerObjects === 'string' && options.answerObjects.length)
		restoreObjects(options.answerObjects, true, true);
	if ('html_input' in gt) restoreObjects(gt.html_input.value, false);

	if (!gt.isStatic) {
		gt.updateText();
		gt.updateUI();
	}
};
