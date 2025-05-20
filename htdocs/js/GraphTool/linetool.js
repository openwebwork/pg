/* global graphTool, JXG */

'use strict';

(() => {
	if (graphTool && graphTool.lineTool) return;

	graphTool.lineTool = {
		Line(gt) {
			return class Line extends gt.GraphObject {
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
						this.constructor.strId,
						this.baseObj.getAttribute('dash') == 0 ? 'solid' : 'dashed',
						...this.definingPts.map(
							(point) =>
								`(${gt.snapRound(point.X(), gt.snapSizeX)},${gt.snapRound(point.Y(), gt.snapSizeY)})`
						)
					].join(',');
				}

				fillCmp(point) {
					return gt.sign(JXG.Math.innerProduct(point, this.baseObj.stdform));
				}

				hasPoint(point) {
					return (
						Math.abs(JXG.Math.innerProduct(point, this.baseObj.stdform)) /
							Math.sqrt(this.baseObj.stdform[1] ** 2 + this.baseObj.stdform[2] ** 2) <
						0.5 / Math.sqrt(gt.board.unitX * gt.board.unitY)
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
					const point1 = gt.createPoint(parseFloat(points[0][0]), parseFloat(points[0][1]));
					const point2 = gt.createPoint(parseFloat(points[1][0]), parseFloat(points[1][1]), point1);
					return new this(point1, point2, /solid/.test(string));
				}
			};
		},

		LineTool(gt) {
			return class LineTool extends gt.GenericTool {
				object = 'line';
				useStandardActivation = true;
				activationHelpText = 'Plot two points on the line.';
				useStandardDeactivation = true;
				constructionObjects = ['point1'];

				constructor(container, iconName, tooltip) {
					super(container, iconName ?? 'line', tooltip ?? 'Line Tool: Graph a line.');
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

				// In phase2 the user has selected a second point.
				// If that point is on the board , then finalize the line.
				phase2(coords) {
					if (!gt.boardHasPoint(coords[1], coords[2])) return;

					// If the current coordinates are the same those of the first point,
					// then use the highlight point coordinates instead.
					if (
						Math.abs(this.point1.X() - gt.snapRound(coords[1], gt.snapSizeX)) < JXG.Math.eps &&
						Math.abs(this.point1.Y() - gt.snapRound(coords[2], gt.snapSizeY)) < JXG.Math.eps
					)
						coords = this.hlObjs.hl_point.coords.usrCoords;

					gt.board.off('up');

					const point1 = this.point1;
					delete this.point1;

					point1.setAttribute(gt.definingPointAttributes);
					point1.on('down', () => gt.onPointDown(point1));
					point1.on('up', () => gt.onPointUp(point1));

					const point2 = gt.createPoint(coords[1], coords[2], point1);
					gt.selectedObj = new gt.graphObjectTypes[this.object](point1, point2, gt.drawSolid);
					gt.selectedObj.focusPoint = point2;
					gt.graphedObjs.push(gt.selectedObj);

					this.finish();
				}
			};
		}
	};
})();
