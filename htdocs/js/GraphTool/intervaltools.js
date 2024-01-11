/* global graphTool, JXG */

(() => {
	if (graphTool && graphTool.intervalTool) return;

	graphTool.intervalTool = {
		Interval: {
			preInit(gt, point1, point2) {
				// If an endpoint is at infinity move the segment end back a bit so it doesn't show up after the end of
				// the arrow.  If the useBracketEnds option is not in use, then make the segment's points a little
				// inside of the actual point so that if the point is not included in the interval and so has a
				// transparent center, then the segment ends are not visible in that transparent center.
				const segment = gt.board.create(
					'segment',
					[
						[
							() =>
								gt.isNegInfX(point1.X())
									? gt.board.getBoundingBox()[0] + 8 / gt.board.unitX
									: gt.isPosInfX(point1.X())
										? gt.board.getBoundingBox()[2] - 8 / gt.board.unitX
										: gt.options.useBracketEnds
											? point1.X()
											: point1.X() + (point1.X() < point2.X() ? 4 : -4) / gt.board.unitX,
							0
						],
						[
							() =>
								gt.isNegInfX(point2.X())
									? gt.board.getBoundingBox()[0] + 8 / gt.board.unitX
									: gt.isPosInfX(point2.X())
										? gt.board.getBoundingBox()[2] - 8 / gt.board.unitX
										: gt.options.useBracketEnds
											? point2.X()
											: point2.X() + (point1.X() < point2.X() ? -4 : 4) / gt.board.unitX,
							0
						]
					],
					{ fixed: true, highlight: false, strokeColor: gt.color.curve, strokeWidth: 4 }
				);

				// Redefine the segment's hasPoint method to return true if either of the end points has the coordinates
				// as well. This is so that a pointer over those points will give focus to the object with the point
				// that the pointer is over activated.
				const segmentHasPoint = segment.hasPoint.bind(segment);
				segment.hasPoint = (x, y) => segmentHasPoint(x, y) || point1.hasPoint(x, y) || point2.hasPoint(x, y);

				return segment;
			},

			postInit(gt, point1, point2, includePoint1, includePoint2) {
				this.supportsSolidDash = false;

				this.definingPts.push(point1, point2);
				this.focusPoint = point1;

				for (const point of [point1, point2]) {
					point.setAttribute({ fixed: gt.isStatic });

					if (gt.isStatic) {
						point.off('down');
						point.off('up');
						point.off('drag');
					} else {
						point.rendNode.addEventListener('focus', () => {
							this.focusPoint = point;
							gt.toolTypes.IncludeExcludePointTool?.updateButtonStatus(point);
						});

						point.text?.setAttribute({
							fontSize: 19,
							highlightStrokeColor: gt.color.pointHighlightDarker,
							cssStyle: 'cursor:auto;font-weight:900'
						});

						// Override hasPoint to make the point effectively bigger when it is a point at infinity.
						const origHasPoint = point.hasPoint.bind(point);
						point.hasPoint = (x, y) => {
							if (gt.isNegInfX(point.X()) || gt.isPosInfX(point.X())) {
								const coordsScr = point.coords.scrCoords;
								return Math.abs(coordsScr[1] - x) < 20 && Math.abs(coordsScr[2] - y) < 20;
							}
							return origHasPoint(x, y);
						};
					}
				}
				point1.setAttribute({
					fillColor: includePoint1 ? gt.color.curve : 'transparent',
					highlightFillColor: includePoint1 ? gt.color.pointHighlightDarker : gt.color.pointHighlight
				});
				point2.setAttribute({
					fillColor: includePoint2 ? gt.color.curve : 'transparent',
					highlightFillColor: includePoint2 ? gt.color.pointHighlightDarker : gt.color.pointHighlight
				});
			},

			blur(gt) {
				this.focused = false;

				for (const point of this.definingPts) {
					this.setFocusBlurPointAttributes(point);
					point.text?.setAttribute({ fontSize: 19, highlight: false, strokeColor: gt.color.curve });
					point.arrow?.setAttribute({ strokeWidth: 4 });
					point.arrow?.rendNodeTriangleEnd.setAttribute('fill', gt.color.curve);
					point.off('over');
					point.off('out');
					point.text?.off('down');
					point.text?.off('up');
				}

				this.baseObj.setAttribute({ strokeColor: gt.color.curve, strokeWidth: 4 });

				gt.updateHelp();
				return false;
			},

			focus(gt) {
				this.focused = true;

				for (const point of this.definingPts) {
					this.setFocusBlurPointAttributes(point);

					// The default layer for text is 9.
					// Setting the layer moves the text in front of any other text objects.
					point.text?.setAttribute({
						fontSize: 23,
						highlight: true,
						strokeColor: gt.color.underConstruction,
						layer: 9
					});

					// The default layer for lines (of which arrows are a part) is 7.
					// Setting this moves the arrow to the front of arrows of other intervals.
					point.arrow?.setAttribute({ strokeWidth: 5, layer: 7 });
					point.arrow?.rendNodeTriangleEnd.setAttribute('fill', gt.color.point);

					// This makes it so that if the pointer is over the point and it is a hidden point at infinity,
					// then it looks like the pointer is over the arrow.  The end arrows don't actually receive
					// hover events, so this has to be done this way.
					point.on('over', () =>
						point.arrow?.rendNodeTriangleEnd.setAttribute('fill', gt.color.pointHighlightDarker)
					);
					point.on('out', () => point.arrow?.rendNodeTriangleEnd.setAttribute('fill', gt.color.point));

					point.text?.on('down', () => {
						point.text.setAttribute({
							cssStyle: 'cursor:none;font-weight:900',
							strokeColor: gt.color.pointHighlightDarker
						});
						point.paired_point?.text?.setAttribute({ cssStyle: 'cursor:none;font-weight:900' });
					});
					point.text?.on('up', () => {
						point.text.setAttribute({
							cssStyle: 'cursor:auto;font-weight:900',
							strokeColor: gt.color.underConstruction
						});
						point.paired_point?.text?.setAttribute({ cssStyle: 'cursor:auto;font-weight:900' });
					});
				}
				this.baseObj.setAttribute({ strokeColor: gt.color.focusCurve, strokeWidth: 5 });

				this.focusPoint.rendNode.focus();

				gt.updateHelp();
				return false;
			},

			isEventTarget(_gt, e) {
				if (this.baseObj.rendNode === e.target) return true;
				return this.definingPts.some(
					(point) =>
						point.rendNode === e.target ||
						point.text?.rendNode === e.target ||
						point.arrow?.rendNode === e.target
				);
			},

			update(gt) {
				const infFirst = gt.isNegInfX(this.definingPts[0].X()) || gt.isPosInfX(this.definingPts[0].X());
				const infLast = gt.isNegInfX(this.definingPts[1].X()) || gt.isPosInfX(this.definingPts[1].X());

				if (infFirst) this.setInfiniteEndPoint(0);
				else this.setFiniteEndPoint(0);

				if (infLast) this.setInfiniteEndPoint(1);
				else this.setFiniteEndPoint(1);
			},

			stringify(gt) {
				const leftEndPoint =
					this.definingPts[0].X() < this.definingPts[1].X() ? this.definingPts[0] : this.definingPts[1];
				const rightEndPoint =
					this.definingPts[0].X() < this.definingPts[1].X() ? this.definingPts[1] : this.definingPts[0];
				const leftX = gt.snapRound(leftEndPoint.X(), gt.snapSizeX);
				const rightX = gt.snapRound(rightEndPoint.X(), gt.snapSizeX);

				return `${gt.isNegInfX(leftX) || leftEndPoint.getAttribute('fillColor') === 'transparent' ? '(' : '['}${
					gt.isNegInfX(leftX) ? '-infinity' : leftX
				},${gt.isPosInfX(rightX) ? 'infinity' : rightX}${
					gt.isPosInfX(rightX) || rightEndPoint.getAttribute('fillColor') === 'transparent' ? ')' : ']'
				}`;
			},

			setSolid() {},

			remove(gt) {
				for (const point of this.definingPts) {
					if (point.text) gt.board.removeObject(point.text);
					if (point.arrow) gt.board.removeObject(point.arrow);
				}
			},

			restore(gt, string) {
				const intervalParts = string.match(
					new RegExp(
						[
							/\s*([[(])\s*/, // left delimiter
							/(-?(?:[0-9]*(?:\.[0-9]*)?|infinity))/, // left end point
							/\s*,\s*/, // comma
							/(-?(?:[0-9]*(?:\.[0-9]*)?|infinity))/, // right end point
							/\s*([\])])\s*/ // right delimiter
						]
							.map((r) => r.source)
							.join('')
					)
				);
				if (!intervalParts || intervalParts.length !== 5) return false;

				const bbox = gt.board.getBoundingBox();

				const point1 = gt.graphObjectTypes.interval.createPoint(
					intervalParts[2] === '-infinity' ? bbox[0] : parseFloat(intervalParts[2]),
					0
				);
				const point2 = gt.graphObjectTypes.interval.createPoint(
					intervalParts[3] === 'infinity' ? bbox[2] : parseFloat(intervalParts[3]),
					0,
					point1
				);
				return new gt.graphObjectTypes.interval(
					point1,
					point2,
					intervalParts[1] === '[',
					intervalParts[4] === ']'
				);
			},

			classMethods: {
				setIncludePoint(gt, include) {
					this.focusPoint?.setAttribute({
						fillColor: include ? gt.color.curve : 'transparent',
						highlightFillColor: include ? gt.color.pointHighlightDarker : gt.color.pointHighlight,
						highlightFillOpacity: gt.options.useBracketEnds || this.focusPoint.arrow ? 0 : include ? 1 : 0.5
					});
				},

				setFocusBlurPointAttributes(gt, point) {
					const attributes = this.focused
						? {
								size: 4,
								strokeWidth: 3,
								strokeColor: gt.color.underConstruction,
								fillColor: gt.color.underConstruction,
								fixed: false,
								highlight: true
							}
						: {
								size: 3,
								strokeWidth: 2,
								strokeColor: gt.color.curve,
								fillColor: gt.color.curve,
								fixed: true,
								highlight: false
							};
					if (!this.focused && point.getAttribute('highlightFillOpacity') !== 0)
						attributes.highlightFillOpacity = 1;
					if (point.getAttribute('fillColor') === 'transparent') {
						attributes.fillColor = 'transparent';
						if (this.focused && point.getAttribute('highlightFillOpacity') !== 0)
							attributes.highlightFillOpacity = 0.5;
					}

					point.setAttribute(attributes);
				},

				setInfiniteEndPoint(gt, index) {
					if (gt.options.useBracketEnds) {
						this.definingPts[index].text.setAttribute({ strokeOpacity: 0, highlightStrokeOpacity: 0 });
					} else {
						this.definingPts[index].setAttribute({
							strokeOpacity: 0,
							fillOpacity: 0,
							highlightStrokeOpacity: 0,
							highlightFillOpacity: 0
						});
					}
					this.definingPts[index].rendNode.classList.add('hidden-inf-point');

					if (!this.definingPts[index].arrow) {
						this.definingPts[index].arrow = gt.board.create(
							'arrow',
							[
								[
									this.definingPts[index].X() +
										(gt.isPosInfX(this.definingPts[index].X()) ? -26 : 26) / gt.board.unitX,
									0
								],
								[this.definingPts[index].X(), 0]
							],
							{
								fixed: true,
								strokeWidth: 4,
								strokeColor: 'transparent',
								highlight: false,
								lastArrow: { type: 2, size: 4 }
							}
						);
						this.definingPts[index].arrow.rendNodeTriangleEnd.setAttribute('fill', gt.color.curve);
					}

					if (this.focused && this.definingPts[index] === this.focusPoint) {
						this.definingPts[index].arrow.rendNodeTriangleEnd.setAttribute('fill', gt.color.point);
						this.definingPts[index].arrow.setAttribute({ strokeWidth: 5 });
					}
				},

				setFiniteEndPoint(gt, index) {
					if (gt.options.useBracketEnds) {
						this.definingPts[index].text.setAttribute({ strokeOpacity: 1, highlightStrokeOpacity: 1 });
					} else {
						this.definingPts[index].setAttribute({
							strokeOpacity: 1,
							fillOpacity: 1,
							highlightStrokeOpacity: 1,
							highlightFillOpacity:
								!gt.options.useBracketEnds &&
								this.focused &&
								this.definingPts[index].getAttribute('fillColor') === 'transparent'
									? 0.5
									: 1
						});
					}
					if (this.definingPts[index].arrow) {
						gt.board.removeObject(this.definingPts[index].arrow);
						delete this.definingPts[index].arrow;
					}
					this.definingPts[index].rendNode.classList.remove('hidden-inf-point');
				}
			},

			helperMethods: {
				// gt.adjustDragPosition prevents paired points from being moved into the same position by a drag, and
				// prevents a point from being moved off the board.  This also ensures that the y coordinate stays at 0.
				pairedPointDrag(gt, e, point) {
					gt.adjustDragPositionRestricted(e, point, point.paired_point);
					if (point.Y() !== 0) point.setPosition(JXG.COORDS_BY_USER, [point.X(), 0]);
					gt.updateObjects();
					gt.updateText();
				},

				createPoint(gt, x, _y, paired_point) {
					const point = gt.board.create('point', [gt.snapRound(x, gt.snapSizeX), 0], {
						snapSizeX: gt.snapSizeX,
						snapSizeY: gt.snapSizeY,
						...gt.graphObjectTypes.interval.definingPointAttributes(),
						...gt.graphObjectTypes.interval.maybeBracketAttributes()
					});
					point.setAttribute({ snapToGrid: true });
					point.on('down', () => gt.graphObjectTypes.interval.pointDown(point));
					point.on('up', () => gt.graphObjectTypes.interval.pointUp(point));
					if (typeof paired_point !== 'undefined') {
						point.paired_point = paired_point;
						paired_point.paired_point = point;
						paired_point.on('drag', (e) => gt.graphObjectTypes.interval.pairedPointDrag(e, paired_point));
						point.on('drag', (e) => gt.graphObjectTypes.interval.pairedPointDrag(e, point));
					}
					if (!gt.options.useBracketEnds) return point;

					point.rendNode.classList.add('hidden-end-point');

					point.text = gt.board.create(
						'text',
						[
							() =>
								point.X() +
								(point.paired_point ? (point.paired_point.X() > point.X() ? 1 : -1) : 0) /
									gt.board.unitX,
							() => 1 / gt.board.unitY,
							() =>
								point.paired_point && point.paired_point.X() < point.X()
									? point.getAttribute('fillColor') === 'transparent'
										? ')'
										: ']'
									: point.getAttribute('fillColor') === 'transparent'
										? '('
										: '['
						],
						{
							fontSize: 23,
							anchorX: 'middle',
							anchorY: 'middle',
							display: 'internal',
							fixed: true,
							strokeColor: gt.color.focusCurve,
							highlightStrokeColor: gt.color.pointHighlightDarker
						}
					);

					return point;
				},

				pointDown(gt, point) {
					if (gt.activeTool !== gt.selectTool) return;

					const thisObj = gt.graphedObjs.filter(
						(obj) => obj.definingPts.filter((pt) => pt === point).length
					)[0];
					if (!thisObj) return;

					if (!thisObj.focused) {
						// Prevent stealing focus from a focused interval with defining point at the same location.
						for (const object of gt.graphedObjs) {
							if (thisObj === object) continue;
							if (object.focused && object.definingPts.some((pt) => point.X() === pt.X())) return;
						}

						thisObj.focus();
					}

					gt.board.containerObj.style.cursor = 'none';
				},

				pointUp(gt) {
					gt.board.containerObj.style.cursor = 'auto';
				},

				// Interval endpoints are slightly larger and use different colors than the graphtool defaults.
				definingPointAttributes(gt) {
					return {
						size: 3,
						fixed: false,
						withLabel: false,
						strokeWidth: 2,
						strokeColor: gt.color.curve,
						fillColor: gt.color.curve, // 'transparent' if not included.
						highlightStrokeWidth: 3,
						highlightStrokeColor: gt.color.pointHighlightDarker,
						highlightFillColor: gt.color.pointHighlightDarker // gt.color.pointHighlight if not included.
					};
				},

				// Attributes added to a point if the useBracketEnds option is in effect.
				// These attributes will make a point invisible, but not with the jsxgraph visible attribute.
				// This is so that the point will still behave as if it were visible.
				maybeBracketAttributes(gt) {
					return gt.options.useBracketEnds
						? { strokeOpacity: 0, fillOpacity: 0, highlightStrokeOpacity: 0, highlightFillOpacity: 0 }
						: {};
				}
			}
		},

		IntervalTool: {
			iconName: 'interval',
			tooltip: 'Interval Tool: Graph an interval.',

			initialize(gt) {
				this.supportsIncludeExclude = true;
				this.supportsSolidDash = false;

				if (gt.options.useBracketEnds) {
					this.button.classList.remove('gt-interval-tool');
					this.button.classList.add('gt-interval-bracket-tool');
				}

				this.phase1 = (coords) => {
					// Don't allow the point to be created off the board.
					if (!gt.boardHasPoint(coords[1], coords[2])) return;

					gt.board.off('up');

					this.point1 = gt.board.create('point', [coords[1], 0], {
						size: 4,
						strokeWidth: 3,
						strokeColor: gt.color.underConstructionFixed,
						fillColor: gt.toolTypes.IncludeExcludePointTool.include
							? gt.color.underConstructionFixed
							: 'transparent',
						highlight: false,
						snapToGrid: true,
						snapSizeX: gt.snapSizeX,
						snapSizeY: gt.snapSizeY,
						withLabel: false,
						...gt.graphObjectTypes.interval.maybeBracketAttributes()
					});
					this.point1.setAttribute({ fixed: true });

					if (gt.options.useBracketEnds) {
						const point = this.point1;
						point.paired_point = this.hlObjs.hl_point;
						point.rendNode.classList.add('hidden-end-point');
						point.text = gt.board.create(
							'text',
							[
								() =>
									point.X() +
									(point.paired_point ? (point.paired_point.X() > point.X() ? 1 : -1) : 0) /
										gt.board.unitX,
								() => 1 / gt.board.unitY,
								() =>
									point.paired_point && point.paired_point.X() < point.X()
										? point.getAttribute('fillColor') === 'transparent'
											? ')'
											: ']'
										: point.getAttribute('fillColor') === 'transparent'
											? '('
											: '['
							],
							{
								fontSize: 23,
								anchorX: 'middle',
								anchorY: 'middle',
								display: 'internal',
								fixed: true,
								highlight: false,
								strokeColor: gt.color.underConstructionFixed,
								cssStyle: 'cursor:none;font-weight:900'
							}
						);
					}

					if (gt.isNegInfX(this.point1.X()) || gt.isPosInfX(this.point1.X())) {
						this.point1.text?.setAttribute({ strokeOpacity: 0 });
						this.point1.setAttribute({ strokeOpacity: 0, fillOpacity: 0 });
					}

					// Get a new x coordinate that is to the right, unless that is off the board.
					// In that case go left instead.
					let newX = this.point1.X() + gt.snapSizeX;
					if (newX > gt.board.getBoundingBox()[2]) newX = this.point1.X() - gt.snapSizeX;

					this.updateHighlights(new JXG.Coords(JXG.COORDS_BY_USER, [newX, 0], gt.board));

					this.helpText =
						'Plot the second endpoint. ' +
						'Move the point to the left end for \\(-\\infty\\), ' +
						'or to the right end for \\(\\infty\\).';
					gt.updateHelp();

					gt.board.on('up', (e) => this.phase2(gt.getMouseCoords(e).usrCoords));

					gt.board.update();
				};

				this.phase2 = (coords) => {
					// Don't allow the second point to be created on the first point or off the board.
					if (
						this.point1.X() === gt.snapRound(coords[1], gt.snapSizeX) ||
						!gt.boardHasPoint(coords[1], coords[2])
					)
						return;

					gt.board.off('up');

					const point1 = this.point1;
					const includePoint1 = point1.getAttribute('fillColor') !== 'transparent';
					point1.setAttribute(gt.graphObjectTypes.interval.definingPointAttributes());
					point1.on('down', () => gt.graphObjectTypes.interval.pointDown(point1));
					point1.on('up', () => gt.graphObjectTypes.interval.pointUp(point1));

					point1.text?.setAttribute({
						strokeColor: gt.color.focusCurve,
						fillColor: gt.color.point,
						highlightStrokeColor: gt.color.pointHighlightDarker,
						cssStyle: 'cursor:auto;font-weight:900'
					});

					const point2 = gt.graphObjectTypes.interval.createPoint(coords[1], 0, point1);
					gt.selectedObj = new gt.graphObjectTypes.interval(
						point1,
						point2,
						includePoint1,
						this.hlObjs.hl_point.getAttribute('fillColor') !== 'transparent'
					);
					gt.selectedObj.focusPoint = point2;
					gt.graphedObjs.push(gt.selectedObj);
					delete this.point1;

					this.finish();
				};
			},

			handleKeyEvent(gt, e) {
				if (!this.hlObjs.hl_point || !gt.board.containerObj.contains(document.activeElement)) return;

				if (e.key === 'Enter' || e.key === ' ') {
					e.preventDefault();
					e.stopPropagation();

					if (this.point1) this.phase2(this.hlObjs.hl_point.coords.usrCoords);
					else this.phase1(this.hlObjs.hl_point.coords.usrCoords);
				}
			},

			updateHighlights(gt, e) {
				this.hlObjs.hl_point?.setAttribute({
					fillColor: gt.toolTypes.IncludeExcludePointTool.include ? gt.color.underConstruction : 'transparent'
				});
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
					this.hlObjs.hl_point = gt.board.create('point', [coords.usrCoords[1], 0], {
						size: 4,
						strokeWidth: 3,
						highlight: false,
						withLabel: false,
						snapToGrid: true,
						snapSizeX: gt.snapSizeX,
						snapSizeY: gt.snapSizeY,
						strokeColor: gt.color.underConstruction,
						fillColor: gt.toolTypes.IncludeExcludePointTool.include
							? gt.color.underConstruction
							: 'transparent',
						...gt.graphObjectTypes.interval.maybeBracketAttributes()
					});

					if (gt.options.useBracketEnds) {
						this.hlObjs.hl_point.rendNode.classList.add('hidden-end-point');
						this.hlObjs.hl_text = gt.board.create(
							'text',
							[
								() =>
									this.hlObjs.hl_point.X() +
									(this.point1 ? (this.point1.X() > this.hlObjs.hl_point.X() ? 1 : -1) : 0) /
										gt.board.unitX,
								() => 1 / gt.board.unitY,
								() =>
									gt.toolTypes.IncludeExcludePointTool.include
										? this.point1?.X() < this.hlObjs.hl_point?.X()
											? ']'
											: '['
										: this.point1?.X() < this.hlObjs.hl_point?.X()
											? ')'
											: '('
							],
							{
								fontSize: 23,
								anchorX: 'middle',
								anchorY: 'middle',
								display: 'internal',
								fixed: true,
								highlight: false,
								strokeColor: gt.color.underConstruction,
								cssStyle: 'cursor:none;font-weight:900'
							}
						);
					}

					this.hlObjs.hl_point.rendNode.focus();
				}

				// Make sure the highlight point is not moved of the board or onto the other point.
				if (e instanceof Event) gt.adjustDragPositionRestricted(e, this.hlObjs.hl_point, this.point1);

				if (this.point1 && !this.hlObjs.hl_segment) {
					this.hlObjs.hl_segment = gt.board.create(
						'segment',
						[
							[
								() =>
									(this.point1
										? gt.isNegInfX(this.point1.X())
											? gt.board.getBoundingBox()[0] + 8 / gt.board.unitX
											: gt.isPosInfX(this.point1.X())
												? gt.board.getBoundingBox()[2] - 8 / gt.board.unitX
												: this.point1.X()
										: 0) +
									(gt.options.useBracketEnds ||
									gt.isNegInfX(this.point1?.X()) ||
									gt.isPosInfX(this.point1?.X())
										? 0
										: (this.point1?.X() < this.hlObjs.hl_point?.X() ? 4 : -4) / gt.board.unitX),
								0
							],
							[
								() =>
									(this.hlObjs.hl_point?.X() ?? 0) +
									(gt.options.useBracketEnds ||
									gt.isNegInfX(this.hlObjs.hl_point?.X()) ||
									gt.isPosInfX(this.hlObjs.hl_point?.X())
										? 0
										: (this.point1?.X() < this.hlObjs.hl_point?.X() ? -4 : 4) / gt.board.unitX),
								0
							]
						],
						{ fixed: true, strokeWidth: 5, strokeColor: gt.color.underConstruction, highlight: false }
					);
					// The default layer for lines (of which arrows are a part) is 7.
					// Setting this moves the arrow to the front of the segment created after it.
					this.hlObjs.hl_arrow?.setAttribute({ layer: 7 });
					this.hlObjs.hl_arrow?.rendNodeTriangleEnd.setAttribute('fill', gt.color.underConstructionFixed);
				}

				if (this.hlObjs.hl_segment) {
					if (
						gt.isNegInfX(gt.snapRound(coords.usrCoords[1], gt.snapSizeX)) ||
						gt.isPosInfX(gt.snapRound(coords.usrCoords[1], gt.snapSizeX))
					) {
						this.hlObjs.hl_segment.setArrow(this.hlObjs.hl_segment.getAttribute('firstArrow'), {
							type: 2,
							size: 4
						});
						if (gt.options.useBracketEnds) this.hlObjs.hl_text.setAttribute({ strokeOpacity: 0 });
						else this.hlObjs.hl_point.setAttribute({ strokeOpacity: 0, fillOpacity: 0 });
						this.hlObjs.hl_point.rendNode.classList.add('hidden-inf-point');
					} else {
						this.hlObjs.hl_segment.setAttribute({ lastArrow: false });
						if (gt.options.useBracketEnds) this.hlObjs.hl_text.setAttribute({ strokeOpacity: 1 });
						else this.hlObjs.hl_point.setAttribute({ strokeOpacity: 1, fillOpacity: 1 });
						this.hlObjs.hl_point.rendNode.classList.remove('hidden-inf-point');
					}
				} else if (this.hlObjs.hl_point) {
					if (
						gt.isNegInfX(gt.snapRound(coords.usrCoords[1], gt.snapSizeX)) ||
						gt.isPosInfX(gt.snapRound(coords.usrCoords[1], gt.snapSizeX))
					) {
						if (!this.hlObjs.hl_arrow) {
							this.hlObjs.hl_arrow = gt.board.create(
								'arrow',
								[
									[
										this.hlObjs.hl_point.X() +
											(gt.isPosInfX(this.hlObjs.hl_point.X()) ? -26 : 26) / gt.board.unitX,
										0
									],
									[this.hlObjs.hl_point.X(), 0]
								],
								{
									fixed: true,
									strokeWidth: 5,
									strokeColor: 'transparent',
									highlight: false,
									lastArrow: { type: 2, size: 4 }
								}
							);
							this.hlObjs.hl_arrow.rendNodeTriangleEnd.setAttribute('fill', gt.color.underConstruction);

							if (gt.options.useBracketEnds) this.hlObjs.hl_text.setAttribute({ strokeOpacity: 0 });
							else this.hlObjs.hl_point.setAttribute({ strokeOpacity: 0, fillOpacity: 0 });
							this.hlObjs.hl_point.rendNode.classList.add('hidden-inf-point');
						}
					} else if (this.hlObjs.hl_arrow) {
						gt.board.removeObject(this.hlObjs.hl_arrow);
						delete this.hlObjs.hl_arrow;

						if (gt.options.useBracketEnds) this.hlObjs.hl_text.setAttribute({ strokeOpacity: 1 });
						else this.hlObjs.hl_point.setAttribute({ strokeOpacity: 1, fillOpacity: 1 });
						this.hlObjs.hl_point.rendNode.classList.remove('hidden-inf-point');
					}
				}

				gt.setTextCoords(this.hlObjs.hl_point.X(), 0);
				gt.board.update();
				return true;
			},

			deactivate(gt) {
				delete this.helpText;
				gt.board.off('up');
				if (this.point1?.text) gt.board.removeObject(this.point1.text);
				if (this.point1) gt.board.removeObject(this.point1);
				delete this.point1;
				gt.board.containerObj.style.cursor = 'auto';
			},

			activate(gt) {
				gt.board.containerObj.style.cursor = 'none';

				// Draw a highlight point on the board.
				this.updateHighlights(new JXG.Coords(JXG.COORDS_BY_USER, [0, 0], gt.board));

				this.helpText =
					'Plot the first endpoint. ' +
					'Move the point to the left end for \\(-\\infty\\), ' +
					'or to the right end for \\(\\infty\\).';
				gt.updateHelp();

				// Wait for the user to select the first point.
				gt.board.on('up', (e) => this.phase1(gt.getMouseCoords(e).usrCoords));
			}
		}
	};
})();

(() => {
	if (graphTool && graphTool.includeExcludePointTool) return;

	graphTool.includeExcludePointTool = {
		IncludeExcludePointTool: {
			parent: undefined,

			initialize(gt, container) {
				gt.toolTypes.IncludeExcludePointTool.include = true;

				const includePointBox = document.createElement('div');
				const includeButtonMessage = 'Include the selected point (i).';
				includePointBox.classList.add('gt-tool-button-pair');
				// The default is to include points.  So the include point button is disabled by default.
				const includePointButtonDiv = document.createElement('div');
				includePointButtonDiv.classList.add('gt-button-div', 'gt-tool-button-pair-top');
				includePointButtonDiv.addEventListener('pointerover', () => gt.setMessageText(includeButtonMessage));
				includePointButtonDiv.addEventListener('pointerout', () => gt.updateHelp());
				gt.toolTypes.IncludeExcludePointTool.includePointButton = document.createElement('button');
				gt.toolTypes.IncludeExcludePointTool.includePointButton.classList.add(
					'gt-button',
					'gt-tool-button',
					gt.options.useBracketEnds ? 'gt-include-point-bracket-tool' : 'gt-include-point-tool'
				);
				gt.toolTypes.IncludeExcludePointTool.includePointButton.type = 'button';
				gt.toolTypes.IncludeExcludePointTool.includePointButton.setAttribute(
					'aria-label',
					includeButtonMessage
				);
				gt.toolTypes.IncludeExcludePointTool.includePointButton.disabled = true;
				gt.toolTypes.IncludeExcludePointTool.includePointButton.addEventListener('click', (e) =>
					gt.toolTypes.IncludeExcludePointTool.toggleIncludeExcludePoint(e, true)
				);
				gt.toolTypes.IncludeExcludePointTool.includePointButton.addEventListener('focus', () =>
					gt.setMessageText(includeButtonMessage)
				);
				gt.toolTypes.IncludeExcludePointTool.includePointButton.addEventListener('blur', () => gt.updateHelp());
				includePointButtonDiv.append(gt.toolTypes.IncludeExcludePointTool.includePointButton);
				includePointBox.append(includePointButtonDiv);

				const excludePointButtonDiv = document.createElement('div');
				const excludeButtonMessage = 'Exclude the selected point (e).';
				excludePointButtonDiv.classList.add('gt-button-div', 'gt-tool-button-pair-bottom');
				excludePointButtonDiv.addEventListener('pointerover', () => gt.setMessageText(excludeButtonMessage));
				excludePointButtonDiv.addEventListener('pointerout', () => gt.updateHelp());
				gt.toolTypes.IncludeExcludePointTool.excludePointButton = document.createElement('button');
				gt.toolTypes.IncludeExcludePointTool.excludePointButton.classList.add(
					'gt-button',
					'gt-tool-button',
					gt.options.useBracketEnds ? 'gt-exclude-point-parenthesis-tool' : 'gt-exclude-point-tool'
				);
				gt.toolTypes.IncludeExcludePointTool.excludePointButton.type = 'button';
				gt.toolTypes.IncludeExcludePointTool.excludePointButton.setAttribute(
					'aria-label',
					excludeButtonMessage
				);
				gt.toolTypes.IncludeExcludePointTool.excludePointButton.addEventListener('click', (e) =>
					gt.toolTypes.IncludeExcludePointTool.toggleIncludeExcludePoint(e, false)
				);
				gt.toolTypes.IncludeExcludePointTool.excludePointButton.addEventListener('focus', () =>
					gt.setMessageText(excludeButtonMessage)
				);
				gt.toolTypes.IncludeExcludePointTool.excludePointButton.addEventListener('blur', () => gt.updateHelp());
				excludePointButtonDiv.append(gt.toolTypes.IncludeExcludePointTool.excludePointButton);
				includePointBox.append(excludePointButtonDiv);
				container.append(includePointBox);
			},

			handleKeyEvent(gt, e) {
				if (e.key === 'e') {
					// If 'e' is pressed change to excluding interval endpoints.
					gt.toolTypes.IncludeExcludePointTool.toggleIncludeExcludePoint(e, false);
				} else if (e.key === 'i') {
					// If 'i' is pressed change to including interval endpoints.
					gt.toolTypes.IncludeExcludePointTool.toggleIncludeExcludePoint(e, true);
				}
			},

			classMethods: {
				helpText(gt) {
					return (gt.selectedObj && typeof gt.selectedObj.setIncludePoint === 'function') ||
						(gt.activeTool && gt.activeTool.supportsIncludeExclude)
						? `Use the ${gt.options.useBracketEnds ? '(' : '\\(\\circ\\)'} or ${
								gt.options.useBracketEnds ? '[' : '\\(\\bullet\\)'
							} button or type e or i to exclude or include the selected endpoint.`
						: '';
				}
			},

			helperMethods: {
				toggleIncludeExcludePoint(gt, e, include) {
					e.preventDefault();
					e.stopPropagation();

					if (gt.selectedObj) {
						// Prevent the gt.board.containerObj focusin handler from
						// moving focus to the last graphed object.
						gt.objectFocusSet = true;

						gt.selectedObj.setIncludePoint?.(include);
						gt.updateText();
					}
					gt.toolTypes.IncludeExcludePointTool.include = include;

					gt.selectedObj?.focus();
					gt.activeTool?.updateHighlights();
					if (!gt.selectedObj && gt.activeTool === gt.selectTool) gt.board.containerObj.focus();

					if (gt.toolTypes.IncludeExcludePointTool.includePointButton)
						gt.toolTypes.IncludeExcludePointTool.includePointButton.disabled = include;
					if (gt.toolTypes.IncludeExcludePointTool.excludePointButton)
						gt.toolTypes.IncludeExcludePointTool.excludePointButton.disabled = !include;
				},

				updateButtonStatus(gt, point) {
					gt.toolTypes.IncludeExcludePointTool.include = point.getAttribute('fillColor') !== 'transparent';
					if (gt.toolTypes.IncludeExcludePointTool.includePointButton)
						gt.toolTypes.IncludeExcludePointTool.includePointButton.disabled =
							gt.toolTypes.IncludeExcludePointTool.include;
					if (gt.toolTypes.IncludeExcludePointTool.excludePointButton)
						gt.toolTypes.IncludeExcludePointTool.excludePointButton.disabled =
							!gt.toolTypes.IncludeExcludePointTool.include;
				}
			}
		}
	};
})();
