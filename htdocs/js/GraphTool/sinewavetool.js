/* global graphTool, JXG */

(() => {
	if (graphTool && graphTool.sineWaveTool) return;

	graphTool.sineWaveTool = {
		SineWave: {
			preInit(gt, shiftPoint, periodPoint, amplitudePoint, solid) {
				[shiftPoint, periodPoint, amplitudePoint].forEach((point) => {
					point.setAttribute(gt.definingPointAttributes);
					if (!gt.isStatic) {
						point.on('down', () => gt.onPointDown(point));
						point.on('up', () => gt.onPointUp(point));
					}
				});
				return gt.graphObjectTypes.sineWave.createSineWave(
					shiftPoint,
					() => (2 * Math.PI) / (periodPoint.X() - shiftPoint.X()),
					() => amplitudePoint.Y() - shiftPoint.Y(),
					solid,
					gt.color.curve
				);
			},

			postInit(_gt, shiftPoint, periodPoint, amplitudePoint) {
				this.definingPts.push(shiftPoint, periodPoint, amplitudePoint);
				this.focusPoint = shiftPoint;
			},

			stringify(gt) {
				return [
					this.baseObj.getAttribute('dash') == 0 ? 'solid' : 'dashed',
					`(${gt.snapRound(this.definingPts[0].X(), gt.snapSizeX)},${gt.snapRound(
						this.definingPts[0].Y(),
						gt.snapSizeY
					)})`,
					gt.snapRound(this.definingPts[1].X() - this.definingPts[0].X(), gt.snapSizeX),
					gt.snapRound(this.definingPts[2].Y() - this.definingPts[0].Y(), gt.snapSizeY)
				].join(',');
			},

			fillCmp(gt, point) {
				return gt.sign(point[2] - this.baseObj.Y(point[1]));
			},

			restore(gt, string) {
				const data = string.match(
					new RegExp(
						[
							gt.pointRegexp, // phase shift and y translation point
							/\s*,\s*/, // comma
							/(-?[0-9]*(?:\.[0-9]*)?)/, // period
							/\s*,\s*/, // comma
							/(-?[0-9]*(?:\.[0-9]*)?)/ // amplitude
						]
							.map((r) => r.source)
							.join('')
					)
				);
				if (!data || data.length !== 5) return false;

				const shiftPoint = gt.graphObjectTypes.sineWave.createPoint(
					gt.snapRound(parseFloat(data[1]), gt.snapSizeX),
					gt.snapRound(parseFloat(data[2]), gt.snapSizeY)
				);
				const periodPoint = gt.graphObjectTypes.sineWave.createPoint(
					gt.snapRound(shiftPoint.X() + parseFloat(data[3]), gt.snapSizeX),
					shiftPoint.Y(),
					shiftPoint
				);
				const amplitudePoint = gt.graphObjectTypes.sineWave.createPoint(
					(3 * shiftPoint.X()) / 4 + periodPoint.X() / 4,
					gt.snapRound(shiftPoint.Y() + parseFloat(data[4]), gt.snapSizeY),
					shiftPoint,
					periodPoint
				);
				return new gt.graphObjectTypes.sineWave(shiftPoint, periodPoint, amplitudePoint, /solid/.test(string));
			},

			helpText(_gt) {
				if (this.focusPoint == this.definingPts[1])
					return 'Note that the selected point can only be moved left and right.';
				else if (this.focusPoint == this.definingPts[2])
					return 'Note that the selected point can only be moved up and down.';
			},

			helperMethods: {
				createSineWave(gt, point, period, amplitude, solid, color) {
					return gt.board.create(
						'curve',
						[
							// x and y coordinate of point on curve
							(x) => x,
							(x) => amplitude() * Math.sin(period() * (x - point.X())) + point.Y(),
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
				},

				// Prevent a point from being moved off the board by a drag. If xRestrict is provided, then also prevent
				// the point from being moved into the same vertical line as that point.  If yRestrict is provided, then
				// also prevent the point from being moved into the same horizontal line as that point.  Note that when
				// this method is called, the point has already been moved by JSXGraph.  Note that this ensures that the
				// sine wave does not degenerate into a line or even worse a point.
				adjustDragPosition(gt, e, point, xRestrict = undefined, yRestrict = undefined) {
					const bbox = gt.board.getBoundingBox();

					// Clamp the coordinates to the board.
					let x = point.X() < bbox[0] ? bbox[0] : point.X() > bbox[2] ? bbox[2] : point.X();
					let y = point.Y() < bbox[3] ? bbox[3] : point.Y() > bbox[1] ? bbox[1] : point.Y();

					if (xRestrict) {
						// Adjust the position of the point if it is on the same
						// vertical line as its xRestrict point.
						let xDir;

						if (e.type === 'pointermove') {
							const coords = gt.getMouseCoords(e);
							xDir = coords.usrCoords[1] > xRestrict.X() ? 1 : -1;
						} else if (e.type === 'keydown') {
							xDir = e.key === 'ArrowLeft' ? -1 : e.key === 'ArrowRight' ? 1 : 0;
						}

						if (Math.abs(x - xRestrict.X()) < JXG.Math.eps) x += xDir * gt.snapSizeX;

						// If the computed new coordinate is off the board,
						// then move the coordinate the other direction instead.
						if (x < bbox[0]) x = bbox[0] + gt.snapSizeX;
						else if (x > bbox[2]) x = bbox[2] - gt.snapSizeX;
					}

					if (yRestrict) {
						// Adjust the position of the point if it is on the same
						// horizontal line as its yRestrict point.
						let yDir;

						if (e.type === 'pointermove') {
							const coords = gt.getMouseCoords(e);
							yDir = coords.usrCoords[2] > yRestrict.Y() ? 1 : -1;
						} else if (e.type === 'keydown') {
							yDir = e.key === 'ArrowUp' ? 1 : e.key === 'ArrowDown' ? -1 : 0;
						}

						if (Math.abs(y - yRestrict.Y()) < JXG.Math.eps) y += yDir * gt.snapSizeY;

						// If the computed new coordinate is off the board,
						// then move the coordinate the other direction instead.
						if (y < bbox[3]) y = bbox[3] + gt.snapSizeY;
						else if (y > bbox[1]) y = bbox[1] - gt.snapSizeY;
					}

					if (
						!gt.boardHasPoint(point.X(), point.Y()) ||
						Math.abs(point.X() - x) >= JXG.Math.eps ||
						Math.abs(point.Y() - y) >= JXG.Math.eps
					)
						point.setPosition(JXG.COORDS_BY_USER, [x, y]);
				},

				pointDrag(gt, e) {
					gt.graphObjectTypes.sineWave.adjustDragPosition(
						e,
						this,
						!this.shiftPoint ? this.periodPoint : !this.periodPoint ? this.shiftPoint : undefined,
						!this.shiftPoint ? this.amplitudePoint : !this.amplitudePoint ? this.shiftPoint : undefined
					);

					const shiftPoint = this.shiftPoint ?? this;
					const periodPoint = this.periodPoint ?? this;
					const amplitudePoint = this.amplitudePoint ?? this;

					if (shiftPoint && periodPoint)
						amplitudePoint?.setPosition(JXG.COORDS_BY_USER, [
							(3 * shiftPoint.X()) / 4 + periodPoint.X() / 4,
							amplitudePoint.Y()
						]);

					if (shiftPoint) periodPoint?.setPosition(JXG.COORDS_BY_USER, [periodPoint.X(), shiftPoint.Y()]);

					gt.setTextCoords(this.X(), this.Y());
					gt.updateObjects();
					gt.updateText();
				},

				createPoint(gt, x, y, shiftPoint = undefined, periodPoint = undefined) {
					const point = gt.board.create('point', [x, y], {
						size: 2,
						snapSizeX: periodPoint ? 1e-10 : gt.snapSizeX,
						snapSizeY: shiftPoint && !periodPoint ? 1e-10 : gt.snapSizeY,
						withLabel: false
					});
					point.setAttribute({ snapToGrid: true });

					if (!gt.isStatic) {
						if (shiftPoint) {
							point.shiftPoint = shiftPoint;
							if (!shiftPoint.periodPoint) shiftPoint.periodPoint = point;
							else if (!shiftPoint.amplitudePoint) shiftPoint.amplitudePoint = point;
							if (!shiftPoint.eventHandlers.drag)
								shiftPoint.on('drag', gt.graphObjectTypes.sineWave.pointDrag);
							point.on('drag', gt.graphObjectTypes.sineWave.pointDrag);
						}

						if (periodPoint) {
							point.periodPoint = periodPoint;
							if (!periodPoint.amplitudePoint) periodPoint.amplitudePoint = point;
						}
					}

					return point;
				}
			}
		},

		SineWaveTool: {
			iconName: 'sine-wave',
			tooltip: 'Sine Wave Tool: Graph a sine wave.',

			initialize(gt) {
				this.supportsSolidDash = true;

				this.phase1 = (coords) => {
					// Don't allow the point to be created off the board
					if (!gt.boardHasPoint(coords[1], coords[2])) return;

					gt.board.off('up');

					this.shiftPoint = gt.graphObjectTypes.sineWave.createPoint(
						gt.snapRound(coords[1], gt.snapSizeX),
						gt.snapRound(coords[2], gt.snapSizeY)
					);
					this.shiftPoint.setAttribute({ fixed: true, highlight: false });

					// Get a new x coordinate that is to the right, unless that is off the board.
					// In that case go left instead.
					let newX = this.shiftPoint.X() + gt.snapSizeX;
					if (newX > gt.board.getBoundingBox()[2]) newX = this.shiftPoint.X() - gt.snapSizeX;

					this.updateHighlights(new JXG.Coords(JXG.COORDS_BY_USER, [newX, this.shiftPoint.Y()], gt.board));

					this.helpText = 'Move the highlighted point left or right to adjust the period.';
					gt.updateHelp();

					gt.board.on('up', (e) => this.phase2(gt.getMouseCoords(e).usrCoords));

					gt.board.update();
				};

				this.phase2 = (coords) => {
					if (!gt.boardHasPoint(coords[1], coords[2])) return;

					// If the current coordinates are on the same vertical line as the first point,
					// then use the highlight point coordinates instead.
					if (Math.abs(this.shiftPoint.X() - gt.snapRound(coords[1], gt.snapSizeX)) < JXG.Math.eps)
						coords = this.hlObjs.hl_point.coords.usrCoords;

					gt.board.off('up');

					this.periodPoint = gt.graphObjectTypes.sineWave.createPoint(
						gt.snapRound(coords[1], gt.snapSizeX),
						this.shiftPoint.Y(),
						this.shiftPoint
					);
					this.periodPoint.setAttribute({ fixed: true, highlight: false });

					// Get a new y coordinate that is above, unless that is off the board.
					// In that case go down instead.
					let newY = this.shiftPoint.Y() + gt.snapSizeY;
					if (newY > gt.board.getBoundingBox()[1]) newY = this.shiftPoint.Y() - gt.snapSizeY;

					this.updateHighlights(
						new JXG.Coords(
							JXG.COORDS_BY_USER,
							[(3 * this.shiftPoint.X()) / 4 + this.periodPoint.X() / 4, newY],
							gt.board
						)
					);

					this.helpText = 'Move the highlighted point up or down to adjust the amplitude.';
					gt.updateHelp();

					gt.board.on('up', (e) => this.phase3(gt.getMouseCoords(e).usrCoords));

					gt.board.update();
				};

				this.phase3 = (coords) => {
					if (!gt.boardHasPoint(coords[1], coords[2])) return;

					// If the current coordinates are on the same horizontal line as the first point,
					// then use the highlight point coordinates instead.
					if (Math.abs(this.shiftPoint.Y() - gt.snapRound(coords[2], gt.snapSizeY)) < JXG.Math.eps)
						coords = this.hlObjs.hl_point.coords.usrCoords;

					gt.board.off('up');

					const amplitudePoint = gt.graphObjectTypes.sineWave.createPoint(
						(3 * this.shiftPoint.X()) / 4 + this.periodPoint.X() / 4,
						gt.snapRound(coords[2], gt.snapSizeY),
						this.shiftPoint,
						this.periodPoint
					);
					gt.selectedObj = new gt.graphObjectTypes.sineWave(
						this.shiftPoint,
						this.periodPoint,
						amplitudePoint,
						gt.drawSolid
					);
					gt.selectedObj.focusPoint = amplitudePoint;
					gt.graphedObjs.push(gt.selectedObj);
					delete this.shiftPoint;
					delete this.periodPoint;

					this.finish();
				};
			},

			handleKeyEvent(gt, e) {
				if (!this.hlObjs.hl_point || !gt.board.containerObj.contains(document.activeElement)) return;

				if (e.key === 'Enter' || e.key === ' ') {
					e.preventDefault();
					e.stopPropagation();

					if (this.periodPoint) this.phase3(this.hlObjs.hl_point.coords.usrCoords);
					else if (this.shiftPoint) this.phase2(this.hlObjs.hl_point.coords.usrCoords);
					else this.phase1(this.hlObjs.hl_point.coords.usrCoords);
				}
			},

			updateHighlights(gt, e) {
				this.hlObjs.hl_period_sine_wave?.setAttribute({ dash: gt.drawSolid ? 0 : 2 });
				this.hlObjs.hl_sine_wave?.setAttribute({ dash: gt.drawSolid ? 0 : 2 });
				this.hlObjs.hl_point?.rendNode.focus();

				let coords;
				if (e instanceof MouseEvent && e.type === 'pointermove') {
					coords = gt.getMouseCoords(e);
					this.hlObjs.hl_point?.setPosition(JXG.COORDS_BY_USER, [
						this.shiftPoint && this.periodPoint
							? (3 * this.shiftPoint.X()) / 4 + this.periodPoint.X() / 4
							: coords.usrCoords[1],
						this.shiftPoint && !this.periodPoint ? this.shiftPoint.Y() : coords.usrCoords[2]
					]);
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

				// Make sure the highlight point is not moved off the board, and that the sine wave is not degenerate.
				if (e instanceof Event) {
					gt.graphObjectTypes.sineWave.adjustDragPosition(
						e,
						this.hlObjs.hl_point,
						this.shiftPoint,
						this.periodPoint
					);
				}

				if (this.periodPoint && !this.hlObjs.hl_sine_wave) {
					// Remove the temporary highlight sine wave from the period phase if it exists.
					if (this.hlObjs.hl_period_sine_wave) {
						gt.board.removeObject(this.hlObjs.hl_period_sine_wave);
						delete this.hlObjs.hl_period_sine_wave;
					}

					this.hlObjs.hl_point.setAttribute({ snapSizeX: 1e-10, snapSizeY: gt.snapSizeY });
					this.hlObjs.hl_point?.setPosition(JXG.COORDS_BY_USER, [
						(3 * this.shiftPoint.X()) / 4 + this.periodPoint.X() / 4,
						this.hlObjs.hl_point.Y()
					]);

					// Local references are needed because the coordinate methods can
					// be called after this.shiftPoint and this.periodPoint are deleted.
					const shiftPoint = this.shiftPoint;
					const periodPoint = this.periodPoint;

					this.hlObjs.hl_sine_wave = gt.graphObjectTypes.sineWave.createSineWave(
						this.shiftPoint,
						() => (2 * Math.PI) / (periodPoint.X() - shiftPoint.X()),
						() => this.hlObjs.hl_point.Y() - shiftPoint.Y(),
						gt.drawSolid
					);
				} else if (this.shiftPoint && !this.periodPoint && !this.hlObjs.hl_period_sine_wave) {
					this.hlObjs.hl_point.setAttribute({ snapSizeY: 1e-10 });

					// A local reference is needed because the coordinate methods
					// can be called after this.shiftPoint is deleted.
					const shiftPoint = this.shiftPoint;

					this.hlObjs.hl_period_sine_wave = gt.graphObjectTypes.sineWave.createSineWave(
						this.shiftPoint,
						() => (2 * Math.PI) / (this.hlObjs.hl_point.X() - shiftPoint.X()),
						() => gt.snapSizeY,
						gt.drawSolid
					);
				}

				gt.setTextCoords(this.hlObjs.hl_point.X(), this.hlObjs.hl_point.Y());
				gt.board.update();
				return true;
			},

			deactivate(gt) {
				delete this.helpText;
				gt.board.off('up');
				['shiftPoint', 'periodPoint', 'amplitudePoint'].forEach(function (point) {
					if (this[point]) gt.board.removeObject(this[point]);
					delete this[point];
				}, this);
				gt.board.containerObj.style.cursor = 'auto';
			},

			activate(gt) {
				gt.board.containerObj.style.cursor = 'none';

				// Draw a highlight point on the board.
				this.updateHighlights(new JXG.Coords(JXG.COORDS_BY_USER, [0, 0], gt.board));

				this.helpText = 'Move the highlighted point to set the phase shift and vertical translation.';
				gt.updateHelp();

				gt.board.on('up', (e) => this.phase1(gt.getMouseCoords(e).usrCoords));
			}
		}
	};
})();
