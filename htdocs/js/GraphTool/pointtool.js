/* global graphTool, JXG */

'use strict';

(() => {
	if (graphTool && graphTool.pointTool) return;

	graphTool.pointTool = {
		Point(gt) {
			return class extends gt.GraphObject {
				static strId = 'point';
				supportsSolidDash = false;

				constructor(x, y) {
					super(
						gt.board.create('point', [x, y], {
							size: 2,
							snapToGrid: true,
							snapSizeX: gt.snapSizeX,
							snapSizeY: gt.snapSizeY,
							withLabel: false,
							strokeColor: gt.color.curve,
							fixed: gt.isStatic,
							highlightStrokeColor: gt.color.underConstruction,
							highlightFillColor: gt.color.pointHighlight,
							tabindex: gt.isStatic ? -1 : 0
						})
					);

					// The base object is also a defining point for a Point.  This makes it so that a point can not
					// steal focus from another focused object that has a defining point at the same location.
					this.definingPts.push(this.baseObj);
					this.focusPoint = this.baseObj;

					if (!gt.isStatic) {
						this.on('down', () => gt.onPointDown(this.baseObj));
						this.on('up', () => gt.onPointUp(this.baseObj));
						this.on('drag', (e) => {
							gt.adjustDragPosition(e, this.baseObj);
							gt.updateText();
						});
					}
				}

				blur() {
					this.focused = false;
					this.baseObj.setAttribute({
						fixed: true,
						highlight: false,
						strokeColor: gt.color.curve,
						strokeWidth: 2
					});
					gt.updateHelp();
				}

				focus() {
					this.focused = true;
					this.baseObj.setAttribute({
						fixed: false,
						highlight: true,
						strokeColor: gt.color.focusCurve,
						strokeWidth: 3
					});

					this.focusPoint.rendNode.focus();
					gt.updateHelp();
				}

				setSolid() {}

				stringify() {
					return [
						this.constructor.strId,
						`(${gt.snapRound(this.baseObj.X(), gt.snapSizeX)},${gt.snapRound(
							this.baseObj.Y(),
							gt.snapSizeY
						)})`
					].join(',');
				}

				updateTextCoords(coords) {
					if (this.baseObj.hasPoint(coords.scrCoords[1], coords.scrCoords[2])) {
						gt.setTextCoords(this.baseObj.X(), this.baseObj.Y());
						return true;
					}
				}

				static restore(string) {
					const points = [];
					let pointData = gt.pointRegexp.exec(string);
					while (pointData) {
						points.push(pointData.slice(1, 3));
						pointData = gt.pointRegexp.exec(string);
					}
					if (points.length < 1) return false;
					return new this(parseFloat(points[0][0]), parseFloat(points[0][1]));
				}
			};
		},

		PointTool(gt) {
			return class extends gt.GenericTool {
				object = 'point';
				useStandardActivation = true;
				activationHelpText = 'Plot a point.';
				useStandardDeactivation = true;

				constructor(container, iconName, tooltip) {
					super(container, iconName ?? 'point', tooltip ?? 'Point Tool: Plot a point.');
				}

				phase1(coords) {
					// Don't allow the point to be created off the board
					if (!gt.boardHasPoint(coords[1], coords[2])) return;

					gt.board.off('up');

					gt.selectedObj = new gt.graphObjectTypes[this.object](coords[1], coords[2]);
					gt.graphedObjs.push(gt.selectedObj);

					this.finish();
				}

				handleKeyEvent(e) {
					if (!this.hlObjs.hl_point) return;

					if (e.key === 'Enter' || e.key === 'Space') {
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
							color: gt.color.underConstruction,
							snapToGrid: true,
							highlight: false,
							snapSizeX: gt.snapSizeX,
							snapSizeY: gt.snapSizeY,
							withLabel: false
						});
						this.hlObjs.hl_point.rendNode.focus();
					}

					// Make sure the highlight point is not moved off the board.
					if (e instanceof Event) gt.adjustDragPosition(e, this.hlObjs.hl_point);

					gt.setTextCoords(this.hlObjs.hl_point.X(), this.hlObjs.hl_point.Y());
					gt.board.update();
					return true;
				}
			};
		}
	};
})();
