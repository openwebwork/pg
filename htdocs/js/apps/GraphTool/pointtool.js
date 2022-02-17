(function() {
	if (graphTool && graphTool.pointTool) return;

	graphTool.pointTool = {
		graphObject: {
			preInit: function(gt, x, y, color) {
				return gt.board.create('point', [x, y], {
					size: 2, snapToGrid: true, snapSizeX: gt.snapSizeX, snapSizeY: gt.snapSizeY, withLabel: false,
					strokeColor: color ? color : gt.underConstructionColor, fixed: gt.isStatic,
					highlightStrokeColor: gt.underConstructionColor, highlightFillColor: gt.pointHighlightColor
				});
			},
			postInit: function(gt) {
				if (!gt.isStatic) {
					this.on('down', function() { gt.board.containerObj.style.cursor = 'none'; });
					this.on('up', function() { gt.board.containerObj.style.cursor = 'auto'; });
					this.on('drag', gt.updateText);
				}
			},
			blur: function(gt) {
				this.baseObj.setAttribute({ highlight: false, strokeColor: gt.curveColor, strokeWidth: 2 });
			},
			focus: function(gt) {
				this.baseObj.setAttribute({ highlight: true, strokeColor: gt.focusCurveColor, strokeWidth: 3 });
			},
			stringify: function(gt) {
				return [
					"(" + gt.snapRound(this.baseObj.X(), gt.snapSizeX) + "," +
					gt.snapRound(this.baseObj.Y(), gt.snapSizeY) + ")"
				].join(",");
			},
			updateTextCoords: function(gt, coords) {
				if (this.baseObj.hasPoint(coords.scrCoords[1], coords.scrCoords[2]))
					gt.setTextCoords(this.baseObj.X(), this.baseObj.Y());
			},
			restore: function(gt, string) {
				var pointData;
				var points = [];
				while (pointData = gt.pointRegexp.exec(string))
				{ points.push(pointData.slice(1, 3)); }
				if (points.length < 1) return false;
				return new gt.graphObjectTypes.point(parseFloat(points[0][0]), parseFloat(points[0][1]), gt.curveColor);
			}
		},
		graphTool: {
			iconName: "point",
			tooltip: "Point Tool",
			updateHighlights: function(gt, coords) {
				if (typeof(coords) === 'undefined') return false;
				if (!('hl_point' in this.hlObjs)) {
					this.hlObjs.hl_point = gt.board.create('point', [coords.usrCoords[1], coords.usrCoords[2]], {
						size: 2, color: gt.underConstructionColor, fixed: true, snapToGrid: true,
						snapSizeX: gt.snapSizeX, snapSizeY: gt.snapSizeY, withLabel: false
					});
				}
				else
					this.hlObjs.hl_point.setPosition(JXG.COORDS_BY_USER, [coords.usrCoords[1], coords.usrCoords[2]]);

				gt.setTextCoords(coords.usrCoords[1], coords.usrCoords[2]);
				gt.board.update();
				return true;
			},
			deactivate: function(gt) {
				gt.board.off('up');
				gt.board.containerObj.style.cursor = 'auto';
			},
			activate: function(gt) {
				gt.board.containerObj.style.cursor = 'none';
				var this_tool = this;
				gt.board.on('up', function(e) {
					var coords = gt.getMouseCoords(e);

					// Don't allow the point to be created off the board
					if (!gt.board.hasPoint(coords.usrCoords[1], coords.usrCoords[2])) return;
					gt.board.off('up');

					gt.selectedObj = new gt.graphObjectTypes.point(coords.usrCoords[1], coords.usrCoords[2]);
					gt.graphedObjs.push(gt.selectedObj);

					this_tool.finish();
				});
			}
		}
	};
})();
