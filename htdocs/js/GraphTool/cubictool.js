/* global graphTool, JXG */

'use strict';

(() => {
	if (graphTool && graphTool.cubicTool) return;

	graphTool.cubicTool = {
		Cubic(gt) {
			return class extends gt.GraphObject {
				static strId = 'cubic';

				constructor(point1, point2, point3, point4, solid) {
					for (const point of [point1, point2, point3, point4]) {
						point.setAttribute(gt.definingPointAttributes());
						if (!gt.isStatic) {
							point.on('down', () => gt.onPointDown(point));
							point.on('up', () => gt.onPointUp(point));
						}
					}
					super(gt.graphObjectTypes.cubic.createCubic(point1, point2, point3, point4, solid, gt.color.curve));
					this.definingPts.push(point1, point2, point3, point4);
					this.focusPoint = point1;
				}

				stringify() {
					return [
						this.constructor.strId,
						this.baseObj.getAttribute('dash') == 0 ? 'solid' : 'dashed',
						...this.definingPts.map(
							(point) =>
								`(${gt.snapRound(point.X(), gt.snapSizeX)},${gt.snapRound(point.Y(), gt.snapSizeY)})`
						)
					].join(',');
				}

				fillCmp(point) {
					return gt.sign(point[2] - this.baseObj.Y(point[1]));
				}

				static restore(string) {
					let pointData = gt.pointRegexp.exec(string);
					const points = [];
					while (pointData) {
						points.push(pointData.slice(1, 3));
						pointData = gt.pointRegexp.exec(string);
					}
					if (points.length < 4) return false;
					const point1 = gt.graphObjectTypes.quadratic.createPoint(
						parseFloat(points[0][0]),
						parseFloat(points[0][1])
					);
					const point2 = gt.graphObjectTypes.quadratic.createPoint(
						parseFloat(points[1][0]),
						parseFloat(points[1][1]),
						[point1]
					);
					const point3 = gt.graphObjectTypes.quadratic.createPoint(
						parseFloat(points[2][0]),
						parseFloat(points[2][1]),
						[point1, point2]
					);
					const point4 = gt.graphObjectTypes.quadratic.createPoint(
						parseFloat(points[3][0]),
						parseFloat(points[3][1]),
						[point1, point2, point3]
					);
					return new this(point1, point2, point3, point4, /solid/.test(string));
				}

				static createCubic(point1, point2, point3, point4, solid, color) {
					return gt.board.create(
						'curve',
						[
							// x and y coordinate of point on curve
							(x) => x,
							(x) => {
								const x1 = point1.X(),
									x2 = point2.X(),
									x3 = point3.X(),
									x4 = point4.X(),
									y1 = point1.Y(),
									y2 = point2.Y(),
									y3 = point3.Y(),
									y4 = point4.Y();
								return (
									((x - x2) * (x - x3) * (x - x4) * y1) / ((x1 - x2) * (x1 - x3) * (x1 - x4)) +
									((x - x1) * (x - x3) * (x - x4) * y2) / ((x2 - x1) * (x2 - x3) * (x2 - x4)) +
									((x - x1) * (x - x2) * (x - x4) * y3) / ((x3 - x1) * (x3 - x2) * (x3 - x4)) +
									((x - x1) * (x - x2) * (x - x3) * y4) / ((x4 - x1) * (x4 - x2) * (x4 - x3))
								);
							},
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
				}
			};
		},

		CubicTool(gt) {
			return class extends gt.GenericTool {
				object = 'cubic';
				supportsSolidDash = true;
				useStandardActivation = true;
				activationHelpText = 'Plot four points on the cubic.';
				useStandardDeactivation = true;
				constructionObjects = ['point1', 'point2', 'point3'];

				constructor(container, iconName, tooltip) {
					super(container, iconName ?? 'cubic', tooltip ?? '4-Point Cubic Tool: Graph a cubic function.');
				}

				phase1(coords) {
					// Don't allow the point to be created off the board.
					if (!gt.boardHasPoint(coords[1], coords[2])) return;

					gt.board.off('up');

					this.point1 = gt.graphObjectTypes.quadratic.createPoint(coords[1], coords[2]);
					this.point1.setAttribute({ fixed: true, highlight: false });

					// Get a new x coordinate that is to the right, unless that is off the board.
					// In that case go left instead.
					let newX = this.point1.X() + gt.snapSizeX;
					if (newX > gt.board.getBoundingBox()[2]) newX = this.point1.X() - gt.snapSizeX;

					this.updateHighlights(new JXG.Coords(JXG.COORDS_BY_USER, [newX, this.point1.Y()], gt.board));

					this.helpText = 'Plot three more points on the cubic.';
					gt.updateHelp();

					gt.board.on('up', (e) => this.phase2(gt.getMouseCoords(e).usrCoords));

					gt.board.update();
				}

				phase2(coords) {
					if (!gt.boardHasPoint(coords[1], coords[2])) return;

					// If the current coordinates are on the same vertical line as the first point,
					// then use the highlight point coordinates instead.
					if (Math.abs(this.point1.X() - gt.snapRound(coords[1], gt.snapSizeX)) < JXG.Math.eps)
						coords = this.hlObjs.hl_point.coords.usrCoords;

					gt.board.off('up');

					this.point2 = gt.graphObjectTypes.quadratic.createPoint(coords[1], coords[2], [this.point1]);
					this.point2.setAttribute({ fixed: true, highlight: false });

					// Get a new x coordinate that is to the right, unless that is off the board.
					// In that case go left instead.
					let newX = this.point2.X() + gt.snapSizeX;
					if (newX === this.point1.X()) newX += gt.snapSizeX;

					if (newX > gt.board.getBoundingBox()[2]) newX = this.point2.X() - gt.snapSizeX;
					if (newX === this.point1.X()) newX -= gt.snapSizeX;

					this.updateHighlights(new JXG.Coords(JXG.COORDS_BY_USER, [newX, this.point2.Y()], gt.board));

					this.helpText = 'Plot two more points on the cubic.';
					gt.updateHelp();

					gt.board.on('up', (e) => this.phase3(gt.getMouseCoords(e).usrCoords));

					gt.board.update();
				}

				phase3(coords) {
					if (!gt.boardHasPoint(coords[1], coords[2])) return;

					// If the current coordinates are on the same vertical line as the first point, or on the same
					// vertical line as the second point, then use the highlight point coordinates instead.
					if (
						Math.abs(this.point1.X() - gt.snapRound(coords[1], gt.snapSizeX)) < JXG.Math.eps ||
						Math.abs(this.point2.X() - gt.snapRound(coords[1], gt.snapSizeX)) < JXG.Math.eps
					)
						coords = this.hlObjs.hl_point.coords.usrCoords;

					gt.board.off('up');
					this.point3 = gt.graphObjectTypes.quadratic.createPoint(coords[1], coords[2], [
						this.point1,
						this.point2
					]);
					this.point3.setAttribute({ fixed: true, highlight: false });

					// Get a new x coordinate that is to the right, unless that is off the board.
					// In that case go left instead.
					let newX = this.point3.X() + gt.snapSizeX;
					while ([this.point1, this.point2].some((other) => newX === other.X())) newX += gt.snapSizeX;

					// If the computed new x coordinate is off the board, then we need to move the point back instead.
					const boundingBox = gt.board.getBoundingBox();
					if (newX < boundingBox[0] || newX > boundingBox[2]) {
						newX = this.point3.X() - gt.snapSizeX;
						while ([this.point1, this.point2].some((other) => newX === other.X())) newX -= gt.snapSizeX;
					}

					this.updateHighlights(new JXG.Coords(JXG.COORDS_BY_USER, [newX, this.point3.Y()], gt.board));

					this.helpText = 'Plot one more point on the cubic.';
					gt.updateHelp();

					gt.board.on('up', (e) => this.phase4(gt.getMouseCoords(e).usrCoords));

					gt.board.update();
				}

				phase4(coords) {
					if (!gt.boardHasPoint(coords[1], coords[2])) return;

					// If the current coordinates are on the same vertical line as the first point, on the same vertical
					// line as the second point, or on the same vertical line as the third point, then use the highlight
					// point coordinates instead.
					if (
						Math.abs(this.point1.X() - gt.snapRound(coords[1], gt.snapSizeX)) < JXG.Math.eps ||
						Math.abs(this.point2.X() - gt.snapRound(coords[1], gt.snapSizeX)) < JXG.Math.eps ||
						Math.abs(this.point3.X() - gt.snapRound(coords[1], gt.snapSizeX)) < JXG.Math.eps
					)
						coords = this.hlObjs.hl_point.coords.usrCoords;

					gt.board.off('up');

					const point4 = gt.graphObjectTypes.quadratic.createPoint(coords[1], coords[2], [
						this.point1,
						this.point2,
						this.point3
					]);
					gt.selectedObj = new gt.graphObjectTypes[this.object](
						this.point1,
						this.point2,
						this.point3,
						point4,
						gt.drawSolid
					);
					gt.selectedObj.focusPoint = point4;
					gt.graphedObjs.push(gt.selectedObj);
					delete this.point1;
					delete this.point2;
					delete this.point3;

					this.finish();
				}

				handleKeyEvent(e) {
					if (!this.hlObjs.hl_point || !gt.board.containerObj.contains(document.activeElement)) return;

					if (e.key === 'Enter' || e.key === ' ') {
						e.preventDefault();
						e.stopPropagation();

						if (this.point3) this.phase4(this.hlObjs.hl_point.coords.usrCoords);
						else if (this.point2) this.phase3(this.hlObjs.hl_point.coords.usrCoords);
						else if (this.point1) this.phase2(this.hlObjs.hl_point.coords.usrCoords);
						else this.phase1(this.hlObjs.hl_point.coords.usrCoords);
					}
				}

				updateHighlights(e) {
					this.hlObjs.hl_line?.setAttribute({ dash: gt.drawSolid ? 0 : 2 });
					this.hlObjs.hl_parabola?.setAttribute({ dash: gt.drawSolid ? 0 : 2 });
					this.hlObjs.hl_cubic?.setAttribute({ dash: gt.drawSolid ? 0 : 2 });
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
							color: gt.color.underConstruction,
							snapToGrid: true,
							snapSizeX: gt.snapSizeX,
							snapSizeY: gt.snapSizeY,
							highlight: false,
							withLabel: false
						});
						this.hlObjs.hl_point.rendNode.focus();
					}

					// Make sure the highlight point is not moved off the board or onto the same
					// vertical line as any of the other points that have already been created.
					if (e instanceof Event) {
						const groupedPoints = [];
						if (this.point1) groupedPoints.push(this.point1);
						if (this.point2) groupedPoints.push(this.point2);
						if (this.point3) groupedPoints.push(this.point3);
						gt.graphObjectTypes.quadratic.adjustDragPosition(e, this.hlObjs.hl_point, groupedPoints);
					}

					if (this.point3 && !this.hlObjs.hl_cubic) {
						// Delete the temporary highlight parabola if it exists.
						if (this.hlObjs.hl_parabola) {
							gt.board.removeObject(this.hlObjs.hl_parabola);
							delete this.hlObjs.hl_parabola;
						}

						this.hlObjs.hl_cubic = gt.graphObjectTypes.cubic.createCubic(
							this.point1,
							this.point2,
							this.point3,
							this.hlObjs.hl_point,
							gt.drawSolid
						);
					} else if (this.point2 && !this.point3 && !this.hlObjs.hl_parabola) {
						// Delete the temporary highlight line if it exists.
						if (this.hlObjs.hl_line) {
							gt.board.removeObject(this.hlObjs.hl_line);
							delete this.hlObjs.hl_line;
						}

						this.hlObjs.hl_parabola = gt.graphObjectTypes.quadratic.createQuadratic(
							this.point1,
							this.point2,
							this.hlObjs.hl_point,
							gt.drawSolid
						);
					} else if (this.point1 && !this.point2 && !this.hlObjs.hl_line) {
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
			};
		}
	};
})();
