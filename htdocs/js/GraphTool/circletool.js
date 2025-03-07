/* global graphTool, JXG */

'use strict';

(() => {
	if (graphTool && graphTool.circleTool) return;

	graphTool.circleTool = {
		Circle(gt) {
			return class Circle extends gt.GraphObject {
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

					// Redefine the circle's hasPoint method to return true if the center point has the given
					// coordinates, so that a pointer over the center point will give focus to the object with the
					// center point activated.
					const circleHasPoint = this.baseObj.hasPoint.bind(this.baseObj);
					this.baseObj.hasPoint = (x, y) => circleHasPoint(x, y) || center.hasPoint(x, y);
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
					return new this(center, point, /solid/.test(string));
				}
			};
		},

		CircleTool(gt) {
			return class CirlceTool extends gt.GenericTool {
				object = 'circle';
				useStandardActivation = true;
				activationHelpText = 'Plot the center of the circle.';
				useStandardDeactivation = true;
				constructionObjects = ['center'];

				constructor(container, iconName, tooltip) {
					super(container, iconName ?? 'circle', tooltip ?? 'Circle Tool: Graph a circle.');
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

				// In phase1 the user has selected a point. If the point is on the board, then create the center of the
				// circle, and set up phase2.
				phase1(coords) {
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

				// In phase2 the user has selected a second point.
				// If that point is on the board, then finalize the circle.
				phase2(coords) {
					if (!gt.boardHasPoint(coords[1], coords[2])) return;

					// If the current coordinates are the same those of the first point,
					// then use the highlight point coordinates instead.
					if (
						Math.abs(this.center.X() - gt.snapRound(coords[1], gt.snapSizeX)) < JXG.Math.eps &&
						Math.abs(this.center.Y() - gt.snapRound(coords[2], gt.snapSizeY)) < JXG.Math.eps
					)
						coords = this.hlObjs.hl_point.coords.usrCoords;

					gt.board.off('up');

					const center = this.center;
					delete this.center;

					center.setAttribute(gt.definingPointAttributes);
					center.on('down', () => gt.onPointDown(center));
					center.on('up', () => gt.onPointUp(center));

					const point = gt.createPoint(coords[1], coords[2], center);
					gt.selectedObj = new gt.graphObjectTypes[this.object](center, point, gt.drawSolid);
					gt.selectedObj.focusPoint = point;
					gt.graphedObjs.push(gt.selectedObj);

					this.finish();
				}
			};
		}
	};
})();
