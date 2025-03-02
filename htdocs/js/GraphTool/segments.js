/* global graphTool, JXG */

'use strict';

(() => {
	if (!graphTool) return;

	const stringify = function (gt) {
		return [
			this.baseObj.getAttribute('dash') === 0 ? 'solid' : 'dashed',
			...this.definingPts.map(
				(point) => `(${gt.snapRound(point.X(), gt.snapSizeX)},${gt.snapRound(point.Y(), gt.snapSizeY)})`
			)
		].join(',');
	};

	const restore = function (gt, string, objectClass) {
		let pointData = gt.pointRegexp.exec(string);
		const points = [];
		while (pointData) {
			points.push(pointData.slice(1, 3));
			pointData = gt.pointRegexp.exec(string);
		}
		if (points.length < 2) return false;
		const point1 = gt.createPoint(parseFloat(points[0][0]), parseFloat(points[0][1]));
		const point2 = gt.createPoint(parseFloat(points[1][0]), parseFloat(points[1][1]), point1);
		return new objectClass(point1, point2, /solid/.test(string));
	};

	const initialize = function (gt, helpText, objectClass) {
		this.phase1 = (coords) => {
			gt.toolTypes.LineTool.prototype.phase1.call(this, coords);
			this.helpText = helpText;
			gt.updateHelp();
		};

		this.phase2 = (coords) => {
			if (!gt.boardHasPoint(coords[1], coords[2])) return;

			// If the current coordinates are on top of the first,
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
			gt.selectedObj = new objectClass(point1, point2, gt.drawSolid);
			gt.selectedObj.focusPoint = point2;
			gt.graphedObjs.push(gt.selectedObj);

			this.finish();
		};
	};

	if (!graphTool.segmentTool) {
		graphTool.segmentTool = {
			Segment: {
				parent: 'line',

				postInit(_gt, _point1, _point2, _solid) {
					this.baseObj.setAttribute({ straightFirst: false, straightLast: false });
				},

				stringify(gt) {
					return stringify.call(this, gt);
				},

				restore(gt, string) {
					return restore.call(this, gt, string, gt.graphObjectTypes.segment);
				}
			},

			SegmentTool: {
				iconName: 'segment',
				tooltip: 'Segment Tool: Graph a line segment.',
				parent: 'LineTool',

				initialize(gt) {
					initialize.call(this, gt, 'Plot the other end of the line segment.', gt.graphObjectTypes.segment);
				},

				updateHighlights(gt, e) {
					const handled = gt.toolTypes.LineTool.prototype.updateHighlights.call(this, e);
					this.hlObjs.hl_line?.setAttribute({ straightFirst: false, straightLast: false });
					return handled;
				},

				activate(gt) {
					this.helpText = 'Plot the points at the ends of the line segment.';
					gt.updateHelp();
				}
			}
		};
	}

	if (!graphTool.vectorTool) {
		graphTool.vectorTool = {
			Vector: {
				parent: 'line',

				postInit(_gt, _point1, _point2, _solid) {
					this.baseObj.setAttribute({ straightFirst: false, straightLast: false });
					this.baseObj.setArrow(false, { type: 1, size: 4 });
				},

				stringify(gt) {
					return stringify.call(this, gt);
				},

				restore(gt, string) {
					return restore.call(this, gt, string, gt.graphObjectTypes.vector);
				}
			},

			VectorTool: {
				iconName: 'vector',
				tooltip: 'Vector Tool: Graph a vector.',
				parent: 'LineTool',

				initialize(gt) {
					initialize.call(this, gt, 'Plot the terminal point of the vector.', gt.graphObjectTypes.vector);
				},

				updateHighlights(gt, e) {
					const handled = gt.toolTypes.LineTool.prototype.updateHighlights.call(this, e);
					this.hlObjs.hl_line?.setAttribute({
						straightFirst: false,
						straightLast: false,
						lastArrow: { type: 1, size: 6 }
					});
					return handled;
				},

				activate(gt) {
					this.helpText = 'Plot the initial point and then the terminal point of the vector.';
					gt.updateHelp();
				}
			}
		};
	}
})();
