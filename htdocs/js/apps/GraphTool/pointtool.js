/* global graphTool, JXG */

(() => {
	if (graphTool && graphTool.pointTool) return;

	graphTool.pointTool = {
		Point: {
			preInit(gt, x, y) {
				return gt.board.create('point', [x, y], {
					size: 2, snapToGrid: true, snapSizeX: gt.snapSizeX, snapSizeY: gt.snapSizeY, withLabel: false,
					strokeColor: gt.color.curve, fixed: gt.isStatic,
					highlightStrokeColor: gt.color.underConstruction, highlightFillColor: gt.color.pointHighlight
				});
			},

			postInit(gt) {
				// The base object is also a defining point for a Point.  This makes it so that a point can not steal
				// focus from another focused object that has a defining point at the same location.
				this.definingPts.push(this.baseObj);
				this.focusPoint = this.baseObj;

				if (!gt.isStatic) {
					this.on('down', () => gt.board.containerObj.style.cursor = 'none');
					this.on('up', () => gt.board.containerObj.style.cursor = 'auto');
					this.on('drag', gt.updateText);
				}
			},

			blur(gt) {
				this.focused = false;
				this.baseObj.setAttribute(
					{ fixed: true, highlight: false, strokeColor: gt.color.curve, strokeWidth: 2 });
				return false;
			},

			focus(gt) {
				this.focused = true;
				this.baseObj.setAttribute(
					{ fixed: false, highlight: true, strokeColor: gt.color.focusCurve, strokeWidth: 3, layer: 9 });

				this.focusPoint.rendNode.focus();
				return false;
			},

			setSolid() {},

			stringify(gt) {
				return `(${
					gt.snapRound(this.baseObj.X(), gt.snapSizeX)},${gt.snapRound(this.baseObj.Y(), gt.snapSizeY)})`;
			},

			updateTextCoords(gt, coords) {
				if (this.baseObj.hasPoint(coords.scrCoords[1], coords.scrCoords[2])) {
					gt.setTextCoords(this.baseObj.X(), this.baseObj.Y());
					return true;
				}
			},

			restore(gt, string) {
				const points = [];
				let pointData = gt.pointRegexp.exec(string);
				while (pointData) {
					points.push(pointData.slice(1, 3));
					pointData = gt.pointRegexp.exec(string);
				}
				if (points.length < 1) return false;
				return new gt.graphObjectTypes.point(parseFloat(points[0][0]), parseFloat(points[0][1]));
			}
		},

		PointTool: {
			iconName: 'point',
			tooltip: 'Point Tool',

			initialize(gt) {
				this.phase1 = (coords) => {
					// Don't allow the point to be created off the board
					if (!gt.boardHasPoint(coords[1], coords[2])) return;

					gt.board.off('up');

					gt.selectedObj = new gt.graphObjectTypes.point(coords[1], coords[2]);
					gt.graphedObjs.push(gt.selectedObj);

					this.finish();
				};
			},

			handleKeyEvent(_gt, e) {
				if (!this.hlObjs.hl_point) return;

				if (e.key === 'Enter' || e.key === 'Space') {
					e.preventDefault();
					e.stopPropagation();

					this.phase1(this.hlObjs.hl_point.coords.usrCoords);
				} else if (['ArrowRight', 'ArrowLeft', 'ArrowDown', 'ArrowUp'].includes(e.key)) {
					this.updateHighlights(this.hlObjs.hl_point.coords);
				}
			},

			updateHighlights(gt, coords) {
				this.hlObjs.hl_point?.rendNode.focus();

				if (typeof coords === 'undefined') return false;

				if (!this.hlObjs.hl_point) {
					this.hlObjs.hl_point = gt.board.create('point', [coords.usrCoords[1], coords.usrCoords[2]], {
						size: 2, color: gt.color.underConstruction, snapToGrid: true, highlight: false,
						snapSizeX: gt.snapSizeX, snapSizeY: gt.snapSizeY, withLabel: false
					});
					this.hlObjs.hl_point.rendNode.focus();
				} else
					this.hlObjs.hl_point.setPosition(JXG.COORDS_BY_USER, [coords.usrCoords[1], coords.usrCoords[2]]);

				gt.setTextCoords(this.hlObjs.hl_point.X(), this.hlObjs.hl_point.Y());
				gt.board.update();
				return true;
			},

			deactivate(gt) {
				gt.board.off('up');
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
