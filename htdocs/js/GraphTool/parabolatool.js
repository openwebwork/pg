/* global graphTool, JXG */

'use strict';

(() => {
	if (graphTool && graphTool.parabolaTool) return;

	graphTool.parabolaTool = {
		Parabola(gt) {
			return class Parabola extends gt.GraphObject {
				static strId = 'parabola';

				constructor(vertex, point, vertical, solid) {
					super(gt.graphObjectTypes.parabola.createParabola(vertex, point, vertical, solid, gt.color.curve));
					this.definingPts.push(vertex, point);
					this.vertical = vertical;
					this.focusPoint = vertex;
				}

				stringify() {
					return [
						this.constructor.strId,
						this.baseObj.getAttribute('dash') == 0 ? 'solid' : 'dashed',
						this.vertical ? 'vertical' : 'horizontal',
						...this.definingPts.map(
							(point) =>
								`(${gt.snapRound(point.X(), gt.snapSizeX)},${gt.snapRound(point.Y(), gt.snapSizeY)})`
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
					return new this(vertex, point, /vertical/.test(string), /solid/.test(string));
				}

				// Parabola graph object.
				// The underlying jsxgraph object is really a curve.  The problem with the
				// jsxgraph parabola object is that it can not be created from the vertex
				// and a point on the graph of the parabola.
				static aVal(vertex, point, vertical) {
					return vertical
						? (point.Y() - vertex.Y()) / Math.pow(point.X() - vertex.X(), 2)
						: (point.X() - vertex.X()) / Math.pow(point.Y() - vertex.Y(), 2);
				}

				static createParabola(vertex, point, vertical, solid, color) {
					if (vertical)
						return gt.board.create(
							'curve',
							[
								// x and y coordinates of point on curve
								(x) => x,
								(x) => this.aVal(vertex, point, vertical) * Math.pow(x - vertex.X(), 2) + vertex.Y(),
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
								(x) => this.aVal(vertex, point, vertical) * Math.pow(x - vertex.Y(), 2) + vertex.X(),
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
				}
			};
		},

		ParabolaTool(gt) {
			return class ParabolaTool extends gt.GenericTool {
				object = 'parabola';
				useStandardActivation = true;
				activationHelpText = 'Plot the vertex of the parabola.';
				useStandardDeactivation = true;
				constructionObjects = ['vertex'];

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

					// Make sure the highlight point is not moved off the board or
					// onto the same horizontal or vertical line as the vertex.
					if (e instanceof Event) gt.adjustDragPositionRestricted(e, this.hlObjs.hl_point, this.vertex);

					if (this.vertex && !this.hlObjs.hl_parabola) {
						this.hlObjs.hl_parabola = gt.graphObjectTypes.parabola.createParabola(
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
					if (!gt.boardHasPoint(coords[1], coords[2])) return;

					// If the current coordinates are on the same horizontal or vertical line as the vertex,
					// then use the highlight point coordinates instead.
					if (
						Math.abs(this.vertex.X() - gt.snapRound(coords[1], gt.snapSizeX)) < JXG.Math.eps ||
						Math.abs(this.vertex.Y() - gt.snapRound(coords[2], gt.snapSizeY)) < JXG.Math.eps
					)
						coords = this.hlObjs.hl_point.coords.usrCoords;

					gt.board.off('up');

					const vertex = this.vertex;
					delete this.vertex;

					vertex.setAttribute(gt.definingPointAttributes);
					vertex.on('down', () => gt.onPointDown(vertex));
					vertex.on('up', () => gt.onPointUp(vertex));

					const point = gt.createPoint(coords[1], coords[2], vertex, true);
					gt.selectedObj = new gt.graphObjectTypes[this.object](vertex, point, this.vertical, gt.drawSolid);
					gt.selectedObj.focusPoint = point;
					gt.graphedObjs.push(gt.selectedObj);

					this.finish();
				}
			};
		},

		VerticalParabolaTool(gt) {
			return class VerticalParabolaTool extends gt.toolTypes.ParabolaTool {
				constructor(container, iconName, tooltip) {
					super(container, true, iconName, tooltip);
				}
			};
		},

		HorizontalParabolaTool(gt) {
			return class HorizontalParabolaTool extends gt.toolTypes.ParabolaTool {
				constructor(container, iconName, tooltip) {
					super(container, false, iconName, tooltip);
				}
			};
		}
	};
})();
