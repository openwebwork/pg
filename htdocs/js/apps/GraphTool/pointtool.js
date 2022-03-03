(() => {
	if (graphTool && graphTool.pointTool) return;

	graphTool.pointTool = {
		graphObject: {
			preInit(gt, x, y, color) {
				return gt.board.create('point', [x, y], {
					size: 2, snapToGrid: true, snapSizeX: gt.snapSizeX, snapSizeY: gt.snapSizeY, withLabel: false,
					strokeColor: color ? color : gt.underConstructionColor, fixed: gt.isStatic,
					highlightStrokeColor: gt.underConstructionColor, highlightFillColor: gt.pointHighlightColor
				});
			},
			postInit(gt) {
				// The base object is also a defining point for a Point.  This makes it so that a point can not steal
				// focus from another focused object that has a defining point at the same location.
				this.definingPts.point = this.baseObj;

				if (!gt.isStatic) {
					this.on('down', () => gt.board.containerObj.style.cursor = 'none');
					this.on('up', () => gt.board.containerObj.style.cursor = 'auto');
					this.on('drag', gt.updateText);
				}
			},
			blur(gt) {
				this.baseObj.setAttribute(
					{ fixed: true, highlight: false, strokeColor: gt.curveColor, strokeWidth: 2 });
			},
			focus(gt) {
				this.baseObj.setAttribute(
					{ fixed: false, highlight: true, strokeColor: gt.focusCurveColor, strokeWidth: 3 });
			},
			stringify(gt) {
				return [
					"(" + gt.snapRound(this.baseObj.X(), gt.snapSizeX) + "," +
					gt.snapRound(this.baseObj.Y(), gt.snapSizeY) + ")"
				].join(",");
			},
			updateTextCoords(gt, coords) {
				if (this.baseObj.hasPoint(coords.scrCoords[1], coords.scrCoords[2]))
					gt.setTextCoords(this.baseObj.X(), this.baseObj.Y());
			},
			restore(gt, string) {
				const points = [];
				let pointData = gt.pointRegexp.exec(string);
				while (pointData) {
					points.push(pointData.slice(1, 3));
					pointData = gt.pointRegexp.exec(string);
				}
				if (points.length < 1) return false;
				return new gt.graphObjectTypes.point(parseFloat(points[0][0]), parseFloat(points[0][1]), gt.curveColor);
			}
		},

		graphTool: {
			iconName: "point",
			tooltip: "Point Tool",
			updateHighlights(gt, coords) {
				if (typeof(coords) === 'undefined') return false;
				if (!('hl_point' in this.hlObjs)) {
					this.hlObjs.hl_point = gt.board.create('point', [coords.usrCoords[1], coords.usrCoords[2]], {
						size: 2, color: gt.underConstructionColor, snapToGrid: true,
						snapSizeX: gt.snapSizeX, snapSizeY: gt.snapSizeY, withLabel: false
					});
				}
				else
					this.hlObjs.hl_point.setPosition(JXG.COORDS_BY_USER, [coords.usrCoords[1], coords.usrCoords[2]]);

				gt.setTextCoords(coords.usrCoords[1], coords.usrCoords[2]);
				gt.board.update();
				return true;
			},
			deactivate(gt) {
				gt.board.off('up');
				gt.board.containerObj.style.cursor = 'auto';
			},
			activate(gt) {
				gt.board.containerObj.style.cursor = 'none';

				gt.board.on('up', (e) => {
					const coords = gt.getMouseCoords(e);

					// Don't allow the point to be created off the board
					if (!gt.board.hasPoint(coords.usrCoords[1], coords.usrCoords[2])) return;
					gt.board.off('up');

					gt.selectedObj = new gt.graphObjectTypes.point(coords.usrCoords[1], coords.usrCoords[2]);
					gt.graphedObjs.push(gt.selectedObj);

					this.finish();
				});
			}
		}
	};
})();
