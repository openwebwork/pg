/* global graphTool, JXG */

'use strict';

(() => {
	if (graphTool && graphTool.fillTool) return;

	graphTool.fillTool = {
		Fill(gt) {
			return class Fill extends gt.GraphObject {
				static strId = 'fill';
				supportsSolidDash = false;

				constructor(point) {
					super(point);

					// Make the point invisible, but not with the jsxgraph visible attribute.
					// The icon will be shown instead.
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
							() => this.constructor.fillIcon(this.focused ? gt.color.pointHighlight : gt.color.fill),
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

						// If the fill point is not on the board, then the flood fill algorithm will loop infinitely.
						// So bail.
						if (!gt.boardHasPoint(...this.baseObj.coords.usrCoords.slice(1))) return;

						const allObjects = gt.graphedObjs
							.concat(gt.staticObjs)
							.filter((o) => !(o instanceof gt.graphObjectTypes['fill']));

						// Determine which side of each object needs to be shaded.  If the point
						// is on a graphed object, then don't fill.
						const a_vals = Array(allObjects.length);
						for (const [i, object] of allObjects.entries()) {
							a_vals[i] = object.fillCmp(this.baseObj.coords.usrCoords);
							if (a_vals[i] == 0) return;
						}

						const bBox = gt.board.getBoundingBox();

						const canvas = document.createElement('canvas');
						canvas.width = gt.board.canvasWidth + 1;
						canvas.height = gt.board.canvasHeight + 1;
						const context = canvas.getContext('2d');
						const colorLayerData = context.getImageData(0, 0, canvas.width, canvas.height);

						const fillRed = Number('0x' + gt.color.fill.slice(1, 3));
						const fillBlue = Number('0x' + gt.color.fill.slice(3, 5));
						const fillGreen = Number('0x' + gt.color.fill.slice(5));

						const fillPixel = (pixelPos) => {
							colorLayerData.data[pixelPos] = fillRed;
							colorLayerData.data[pixelPos + 1] = fillBlue;
							colorLayerData.data[pixelPos + 2] = fillGreen;
							colorLayerData.data[pixelPos + 3] = 255;
						};

						if (gt.options.useFloodFill) {
							const isFilled = (pixelPos) =>
								colorLayerData.data[pixelPos] == fillRed &&
								colorLayerData.data[pixelPos + 1] == fillBlue &&
								colorLayerData.data[pixelPos + 2] == fillGreen;

							const isBoundaryPixel = (x, y, fromDir) => {
								const curPixel = [1, bBox[0] + x / gt.board.unitX, bBox[1] - y / gt.board.unitY];
								const fromPixel = [
									1,
									curPixel[1] + fromDir[0] / gt.board.unitX,
									curPixel[2] + fromDir[1] / gt.board.unitY
								];
								for (const [i, object] of allObjects.entries()) {
									if (object.onBoundary(curPixel, a_vals[i], fromPixel)) return true;
								}
								return false;
							};

							const pixelStack = [
								[
									Math.round((this.definingPts[0].X() - bBox[0]) * gt.board.unitX),
									Math.round((bBox[1] - this.definingPts[0].Y()) * gt.board.unitY)
								]
							];

							while (pixelStack.length) {
								const newPos = pixelStack.pop();
								let x = newPos[0];
								let y = newPos[1];

								// Get current pixel position.
								let pixelPos = (y * canvas.width + x) * 4;

								// Go up until the boundary of the fill region or the edge of the canvas is reached.
								while (y >= 0 && !isBoundaryPixel(x, y, [0, 1])) {
									y -= 1;
									pixelPos -= canvas.width * 4;
								}

								y += 1;
								pixelPos += canvas.width * 4;
								let reachLeft = false;
								let reachRight = false;

								// Go down until the boundary of the fill region or the edge of the canvas is reached.
								while (y < canvas.height && !isBoundaryPixel(x, y, [0, -1])) {
									// FIXME: This should not be needed, but for some reason when several segments or
									// vectors are plotted in certain positions the algorithm starts filling already
									// filled pixels repeatedly and loops infinitely. The similar Perl code in the macro
									// does not do this.
									if (isFilled(pixelPos)) break;

									fillPixel(pixelPos);

									// While proceeding down check to the left and right to see
									// if the fill region extends in those directions.
									if (x > 0) {
										if (!isFilled(pixelPos - 4) && !isBoundaryPixel(x - 1, y, [1, 0])) {
											if (!reachLeft) {
												// Add pixel to stack
												pixelStack.push([x - 1, y]);
												reachLeft = true;
											}
										} else reachLeft = false;
									}

									if (x < canvas.width - 1) {
										if (!isFilled(pixelPos + 4) && !isBoundaryPixel(x + 1, y, [-1, 0])) {
											if (!reachRight) {
												// Add pixel to stack
												pixelStack.push([x + 1, y]);
												reachRight = true;
											}
										} else reachRight = false;
									}

									y += 1;
									pixelPos += canvas.width * 4;
								}
							}
						} else {
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
						}

						context.putImageData(colorLayerData, 0, 0);
						const dataURL = canvas.toDataURL('image/png');
						canvas.remove();

						this.fillObj = gt.board.create(
							'image',
							[dataURL, [bBox[0], bBox[3]], [bBox[2] - bBox[0], bBox[1] - bBox[3]]],
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
						this.constructor.strId,
						`(${gt.snapRound(this.baseObj.X(), gt.snapSizeX)},${gt.snapRound(
							this.baseObj.Y(),
							gt.snapSizeY
						)})`
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
					return new this(gt.createPoint(parseFloat(points[0][0]), parseFloat(points[0][1])));
				}

				// This is the icon used for the fill tool and fill graph object.
				static fillIcon(color) {
					return (
						'data:image/svg+xml,' +
						encodeURIComponent(
							"<svg xmlns:svg='http://www.w3.org/2000/svg' xmlns='http://www.w3.org/2000/svg' " +
								"version='1.1' viewBox='0 0 32 32' height='32px' width='32px'><g>" +
								"<path d='m 13.466084,10.267728 -4.9000003,8.4 4.9000003,4.9 8.4,-4.9 z' " +
								`opacity='1' fill='${color}' fill-opacity='1' stroke='#000000' ` +
								"stroke-width='1.3' stroke-linecap='butt' stroke-linejoin='miter' " +
								"stroke-opacity='1' stroke-miterlimit='4' stroke-dasharray='none' />" +
								"<path d='M 16.266084,15.780798 V 6.273173' fill='none' stroke='#000000' " +
								"stroke-width='1.38' stroke-linecap='round' stroke-linejoin='miter' " +
								"stroke-miterlimit='4' stroke-dasharray='none' stroke-opacity='1' />" +
								"<path d='m 20,16 c 0,0 2,-1 3,0 1,0 1,1 2,2 0,1 0,2 0,3 0,1 0,2 0,2 0,0 -1,0 " +
								"-1,0 -1,-1 -1,-1 -1,-2 0,-1 0,-1 -1,-2 0,-1 0,-2 -1,-2 -1,-1 -2,-1 -1,-1 z' " +
								"fill='#0900ff' fill-opacity='1' stroke='#000000' stroke-width='0.7px' " +
								"stroke-linecap='butt' stroke-linejoin='miter' stroke-opacity='1' />" +
								'</g></svg>'
						)
					);
				}
			};
		},

		FillTool(gt) {
			return class FillTool extends gt.GenericTool {
				object = 'fill';
				useStandardActivation = true;
				activationHelpText = 'Choose a point in the region to be filled.';
				useStandardDeactivation = true;

				constructor(container, iconName, tooltip) {
					super(
						container,
						iconName ?? 'fill',
						tooltip ?? 'Region Shading Tool: Shade a region in the graph.'
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
						this.hlObjs.hl_point?.setPosition(JXG.COORDS_BY_USER, [
							coords.usrCoords[1],
							coords.usrCoords[2]
						]);
					} else if (e instanceof KeyboardEvent && e.type === 'keydown') {
						coords = this.hlObjs.hl_point.coords;
					} else if (e instanceof JXG.Coords) {
						coords = e;
						this.hlObjs.hl_point?.setPosition(JXG.COORDS_BY_USER, [
							coords.usrCoords[1],
							coords.usrCoords[2]
						]);
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
								gt.graphObjectTypes.fill.fillIcon(gt.color.fill),
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

				phase1(coords) {
					// Don't allow the fill to be created off the board
					if (!gt.boardHasPoint(coords[1], coords[2])) return;

					gt.board.off('up');

					gt.selectedObj = new gt.graphObjectTypes[this.object](gt.createPoint(coords[1], coords[2]));
					gt.graphedObjs.push(gt.selectedObj);

					this.finish();
				}
			};
		}
	};
})();
