/* global graphTool, JXG */

(() => {
	if (graphTool && graphTool.quadraticTool) return;

	graphTool.quadraticTool = {
		Quadratic: {
			preInit(gt, point1, point2, point3, solid) {
				[point1, point2, point3].forEach((point) => {
					point.setAttribute(gt.definingPointAttributes);
					point.on('down', () => gt.board.containerObj.style.cursor = 'none');
					point.on('up', () => gt.board.containerObj.style.cursor = 'auto');
				});
				return gt.graphObjectTypes.quadratic.createQuadratic(point1, point2, point3, solid, gt.color.curve);
			},

			postInit(_gt, point1, point2, point3) {
				this.definingPts.push(point1, point2, point3);
				this.focusPoint = point1;
			},

			handleKeyEvent(gt, e, el) {
				if (e.key !== 'ArrowLeft' && e.key !== 'ArrowRight') return;

				// Make sure that this point is not moved onto the same vertical line as another point.
				const pointIndex = this.definingPts.findIndex((pt) => pt.id === el.id);
				if (pointIndex > -1) {
					let x = el.X();
					const dir = (e.key === 'ArrowLeft' ? -1 : 1) * gt.snapSizeX;

					while (this.definingPts.some((other, i) => i !== pointIndex && x === other.X())) x += dir;

					// If the computed new x coordinate is off the board, then we need to move the point back instead.
					const boundingBox = gt.board.getBoundingBox();
					if (x < boundingBox[0] || x > boundingBox[2]) {
						x = el.X() - dir;
						while (this.definingPts.some((other, i) => i !== pointIndex && x === other.X())) x -= dir;
					}

					el.setPosition(JXG.COORDS_BY_USER, [x, el.Y()]);
				}
			},

			stringify(gt) {
				return [
					this.baseObj.getAttribute('dash') == 0 ? 'solid' : 'dashed',
					...this.definingPts.map(
						(point) => `(${gt.snapRound(point.X(), gt.snapSizeX)},${gt.snapRound(point.Y(), gt.snapSizeY)})`
					)
				].join(',');
			},

			fillCmp(gt, point) {
				return gt.sign(point[2] - this.baseObj.Y(point[1]));
			},

			restore(gt, string) {
				let pointData = gt.pointRegexp.exec(string);
				const points = [];
				while (pointData) {
					points.push(pointData.slice(1, 3));
					pointData = gt.pointRegexp.exec(string);
				}
				if (points.length < 3) return false;
				const point1 = gt.graphObjectTypes.quadratic.createPoint(
					parseFloat(points[0][0]), parseFloat(points[0][1]));
				const point2 = gt.graphObjectTypes.quadratic.createPoint(
					parseFloat(points[1][0]), parseFloat(points[1][1]), [point1]);
				const point3 = gt.graphObjectTypes.quadratic.createPoint(
					parseFloat(points[2][0]), parseFloat(points[2][1]), [point1, point2]);
				return new gt.graphObjectTypes.quadratic(point1, point2, point3, /solid/.test(string));
			},

			helperMethods: {
				createQuadratic(gt, point1, point2, point3, solid, color) {
					return gt.board.create('curve', [
						// x and y coordinates of point on curve
						(x) => x,
						(x) => {
							const x1 = point1.X(), x2 = point2.X(), x3 = point3.X(),
								y1 = point1.Y(), y2 = point2.Y(), y3 = point3.Y();
							return (x - x2) * (x - x3) * y1 / ((x1 - x2) * (x1 - x3))
								+ (x - x1) * (x - x3) * y2 / ((x2 - x1) * (x2 - x3))
								+ (x - x1) * (x - x2) * y3 / ((x3 - x1) * (x3 - x2));
						},
						// domain minimum and maximum
						() => gt.board.getBoundingBox()[0], () => gt.board.getBoundingBox()[2]
					], {
						strokeWidth: 2, highlight: false, strokeColor: color ? color : gt.color.underConstruction,
						dash: solid ? 0 : 2
					});
				},

				pairedPointDrag(gt, e) {
					const coords = gt.getMouseCoords(e);
					let left_x = this.X(), right_x = this.X();

					while (this.paired_points.some((pairedPoint) => left_x == pairedPoint.X()))
						left_x -= gt.snapSizeX;
					while (this.paired_points.some((pairedPoint) => right_x == pairedPoint.X()))
						right_x += gt.snapSizeX;

					if (this.X() != left_x && this.X() != right_x) {
						const left_dist = Math.abs(coords.usrCoords[1] - left_x);
						const right_dist = Math.abs(coords.usrCoords[1] - right_x);
						this.setPosition(JXG.COORDS_BY_USER, [
							left_x < gt.board.getBoundingBox()[0] ? right_x
								: (left_dist < right_dist || right_x > gt.board.getBoundingBox()[2]) ? left_x : right_x,
							this.Y()
						]);
					}

					gt.updateObjects();
					gt.updateText();
				},

				createPoint(gt, x, y, paired_points) {
					const point = gt.board.create('point', [x, y], {
						size: 2, snapToGrid: true, snapSizeX: gt.snapSizeX, snapSizeY: gt.snapSizeY, withLabel: false
					});
					if (typeof paired_points !== 'undefined' && paired_points.length) {
						point.paired_points = [];
						paired_points.forEach((paired_point) => {
							point.paired_points.push(paired_point);
							if (!paired_point.paired_points) {
								paired_point.paired_points = [];
								paired_point.on('drag', gt.graphObjectTypes.quadratic.pairedPointDrag);
							}
							paired_point.paired_points.push(point);
							if (!paired_point.eventHandlers.drag ||
								paired_point.eventHandlers.drag.every((dragHandler) =>
									dragHandler.handler !== gt.graphObjectTypes.quadratic.pairedPointDrag)
							)
								paired_point.on('drag', gt.graphObjectTypes.quadratic.pairedPointDrag);
						});
						point.on('drag', gt.graphObjectTypes.quadratic.pairedPointDrag, point);
					}
					return point;
				}
			}
		},

		QuadraticTool: {
			iconName: 'quadratic',
			tooltip: '3-Point Quadratic Tool',

			initialize(gt) {
				this.phase1 = (coords) => {
					// Don't allow the point to be created off the board.
					if (!gt.boardHasPoint(coords[1], coords[2])) return;

					gt.board.off('up');

					this.point1 = gt.graphObjectTypes.quadratic.createPoint(coords[1], coords[2]);
					this.point1.setAttribute({ fixed: true });

					// Get a new x coordinate that is to the right, unless that is off the board.
					// In that case go left instead.
					let newX = this.point1.X() + gt.snapSizeX;
					if (newX > gt.board.getBoundingBox()[2]) newX = this.point1.X() - gt.snapSizeX;

					this.updateHighlights(new JXG.Coords(JXG.COORDS_BY_USER, [newX, this.point1.Y()], gt.board));

					gt.board.on('up', (e) => this.phase2(gt.getMouseCoords(e).usrCoords));

					gt.board.update();
				};

				this.phase2 = (coords) => {
					// Don't allow the second point to be created on the same
					// vertical line as the first point or off the board.
					if (this.point1.X() == gt.snapRound(coords[1], gt.snapSizeX) ||
						!gt.boardHasPoint(coords[1], coords[2]))
						return;

					gt.board.off('up');

					this.point2 = gt.graphObjectTypes.quadratic.createPoint(coords[1], coords[2], [this.point1]);
					this.point2.setAttribute({ fixed: true });

					// Get a new x coordinate that is to the right, unless that is off the board.
					// In that case go left instead.
					let newX = this.point2.X() + gt.snapSizeX;
					if (newX === this.point1.X()) newX += gt.snapSizeX;

					if (newX > gt.board.getBoundingBox()[2]) newX = this.point2.X() - gt.snapSizeX;
					if (newX === this.point1.X()) newX -= gt.snapSizeX;

					this.updateHighlights(new JXG.Coords(JXG.COORDS_BY_USER, [newX, this.point2.Y()], gt.board));

					gt.board.on('up', (e) => this.phase3(gt.getMouseCoords(e).usrCoords));

					gt.board.update();
				};

				this.phase3 = (coords) => {
					// Don't allow the third point to be created on the same vertical line as the
					// first point, on the same vertical line as the second point, or off the board.
					if (this.point1.X() == gt.snapRound(coords[1], gt.snapSizeX) ||
						this.point2.X() == gt.snapRound(coords[1], gt.snapSizeX) ||
						!gt.boardHasPoint(coords[1], coords[2]))
						return;

					gt.board.off('up');

					const point3 = gt.graphObjectTypes.quadratic.createPoint(coords[1], coords[2],
						[this.point1, this.point2]);
					gt.selectedObj = new gt.graphObjectTypes.quadratic(this.point1, this.point2, point3, gt.drawSolid);
					gt.selectedObj.focusPoint = point3;
					gt.graphedObjs.push(gt.selectedObj);
					delete this.point1;
					delete this.point2;

					this.finish();
				};
			},

			handleKeyEvent(gt, e) {
				if (!this.hlObjs.hl_point || !gt.board.containerObj.contains(document.activeElement)) return;

				if (e.key === 'Enter' || e.key === ' ') {
					e.preventDefault();
					e.stopPropagation();

					if (this.point2) this.phase3(this.hlObjs.hl_point.coords.usrCoords);
					else if (this.point1) this.phase2(this.hlObjs.hl_point.coords.usrCoords);
					else this.phase1(this.hlObjs.hl_point.coords.usrCoords);
				} else if (['ArrowRight', 'ArrowLeft', 'ArrowDown', 'ArrowUp'].includes(e.key)) {
					if (e.key === 'ArrowRight' || e.key === 'ArrowLeft') {
						// Make sure the highlight point is not moved onto the same vertical line as any of the other
						// points that have already been created.
						const others = [];
						if (this.point1) others.push(this.point1);
						if (this.point2) others.push(this.point2);

						let x = this.hlObjs.hl_point.X();
						while (others.some((other) => x === other.X()))
							x += (e.key === 'ArrowRight' ? 1 : -1) * gt.snapSizeX;

						// If the computed new x coordinate is off the board,
						// then we need to move the point back instead.
						const boundingBox = gt.board.getBoundingBox();
						if (x < boundingBox[0] || x > boundingBox[2]) {
							x = this.hlObjs.hl_point.X();
							while (others.some((other) => x === other.X()))
								x += (e.key === 'ArrowRight' ? -1 : 1) * gt.snapSizeX;
						}

						if (x !== this.hlObjs.hl_point.X())
							this.hlObjs.hl_point.setPosition(JXG.COORDS_BY_USER, [x, this.hlObjs.hl_point.Y()]);
					}

					this.updateHighlights(this.hlObjs.hl_point.coords);
				}
			},

			updateHighlights(gt, coords) {
				if (this.hlObjs.hl_line) this.hlObjs.hl_line.setAttribute({ dash: gt.drawSolid ? 0 : 2 });
				if (this.hlObjs.hl_quadratic) this.hlObjs.hl_quadratic.setAttribute({ dash: gt.drawSolid ? 0 : 2 });
				this.hlObjs.hl_point?.rendNode.focus();

				if (typeof coords === 'undefined') return;

				const new_x = gt.snapRound(coords.usrCoords[1], gt.snapSizeX);
				if ((this.point1 && new_x == this.point1.X()) || (this.point2 && new_x == this.point2.X())) return;

				if (this.hlObjs.hl_point) {
					this.hlObjs.hl_point.setPosition(JXG.COORDS_BY_USER, [coords.usrCoords[1], coords.usrCoords[2]]);
				} else {
					this.hlObjs.hl_point = gt.board.create('point', [coords.usrCoords[1], coords.usrCoords[2]], {
						size: 2, color: gt.color.underConstruction, snapToGrid: true,
						snapSizeX: gt.snapSizeX, snapSizeY: gt.snapSizeY,
						highlight: false, withLabel: false
					});
					this.hlObjs.hl_point.rendNode.focus();
				}

				if (this.point2 && !this.hlObjs.hl_quadratic) {
					// Delete the temporary highlight line if it exists.
					if (this.hlObjs.hl_line) {
						gt.board.removeObject(this.hlObjs.hl_line);
						delete this.hlObjs.hl_line;
					}

					this.hlObjs.hl_quadratic = gt.graphObjectTypes.quadratic.createQuadratic(
						this.point1, this.point2, this.hlObjs.hl_point, gt.drawSolid);
				} else if (this.point1 && !this.point2 && !this.hlObjs.hl_line) {
					this.hlObjs.hl_line = gt.board.create('line', [this.point1, this.hlObjs.hl_point], {
						fixed: true, strokeColor: gt.color.underConstruction, highlight: false,
						dash: gt.drawSolid ? 0 : 2
					});
				}

				gt.setTextCoords(this.hlObjs.hl_point.X(), this.hlObjs.hl_point.Y());
				gt.board.update();
				return true;
			},

			deactivate(gt) {
				gt.board.off('up');
				if (this.point1) gt.board.removeObject(this.point1);
				delete this.point1;
				if (this.point2) gt.board.removeObject(this.point2);
				delete this.point2;
				gt.board.containerObj.style.cursor = 'auto';
			},

			activate(gt) {
				gt.board.containerObj.style.cursor = 'none';

				// Draw a highlight point on the board.
				this.updateHighlights(new JXG.Coords(JXG.COORDS_BY_USER, [0, 0], gt.board));

				gt.board.on('up', (e) => this.phase1(gt.getMouseCoords(e).usrCoords));
			}
		}
	};
})();
