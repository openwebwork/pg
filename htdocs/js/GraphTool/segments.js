/* global graphTool */

'use strict';

(() => {
	if (!graphTool) return;

	if (!graphTool.segmentTool) {
		graphTool.segmentTool = {
			Segment(gt) {
				return class extends gt.graphObjectTypes.line {
					static strId = 'segment';

					constructor(point1, point2, solid) {
						super(point1, point2, solid);
						this.baseObj.setAttribute({ straightFirst: false, straightLast: false });
					}

					fillCmp(point) {
						return (
							super.fillCmp(point) ||
							(point[1] >= Math.min(this.definingPts[0].X(), this.definingPts[1].X()) &&
							point[1] <= Math.max(this.definingPts[0].X(), this.definingPts[1].X()) &&
							point[2] >= Math.min(this.definingPts[0].Y(), this.definingPts[1].Y()) &&
							point[2] <= Math.max(this.definingPts[0].Y(), this.definingPts[1].Y())
								? 0
								: 1)
						);
					}

					onBoundary(point, _aVal, from) {
						if (
							!(
								point[1] >
									Math.min(this.definingPts[0].X(), this.definingPts[1].X()) - 0.5 / gt.board.unitX &&
								point[1] <
									Math.max(this.definingPts[0].X(), this.definingPts[1].X()) + 0.5 / gt.board.unitX &&
								point[2] >
									Math.min(this.definingPts[0].Y(), this.definingPts[1].Y()) - 0.5 / gt.board.unitY &&
								point[2] <
									Math.max(this.definingPts[0].Y(), this.definingPts[1].Y()) + 0.5 / gt.board.unitY
							)
						)
							return 0;

						const crossingStdForm = [
							point[1] * from[2] - point[2] * from[1],
							point[2] - from[2],
							from[1] - point[1]
						];
						const pointSide = JXG.Math.innerProduct(point, this.baseObj.stdform);

						return (
							(JXG.Math.innerProduct(from, this.baseObj.stdform) > 0 != pointSide > 0 &&
								JXG.Math.innerProduct(this.baseObj.point1.coords.usrCoords, crossingStdForm) > 0 !=
									JXG.Math.innerProduct(this.baseObj.point2.coords.usrCoords, crossingStdForm) > 0) ||
							Math.abs(pointSide) /
								Math.sqrt(this.baseObj.stdform[1] ** 2 + this.baseObj.stdform[2] ** 2) <
								0.5 / Math.sqrt(gt.board.unitX * gt.board.unitY)
						);
					}
				};
			},

			SegmentTool(gt) {
				return class extends gt.toolTypes.LineTool {
					object = 'segment';
					activationHelpText = 'Plot the points at the ends of the line segment.';

					constructor(container, iconName, tooltip) {
						super(container, iconName ?? 'segment', tooltip ?? 'Segment Tool: Graph a line segment.');
					}

					updateHighlights(e) {
						const handled = super.updateHighlights(e);
						this.hlObjs.hl_line?.setAttribute({ straightFirst: false, straightLast: false });
						return handled;
					}

					phase1(coords) {
						super.phase1(coords);
						this.helpText = 'Plot the other end of the line segment.';
						gt.updateHelp();
					}
				};
			}
		};
	}

	if (!graphTool.vectorTool) {
		graphTool.vectorTool = {
			Vector(gt) {
				return class extends gt.graphObjectTypes.segment {
					static strId = 'vector';

					constructor(point1, point2, solid) {
						super(point1, point2, solid);
						this.baseObj.setArrow(false, { type: 1, size: 4 });
					}
				};
			},

			VectorTool(gt) {
				return class extends gt.toolTypes.LineTool {
					object = 'vector';
					activationHelpText = 'Plot the initial point and then the terminal point of the vector.';

					constructor(container, iconName, tooltip) {
						super(container, iconName ?? 'vector', tooltip ?? 'Vector Tool: Graph a vector.');
					}

					updateHighlights(e) {
						const handled = super.updateHighlights(e);
						this.hlObjs.hl_line?.setAttribute({
							straightFirst: false,
							straightLast: false,
							lastArrow: { type: 1, size: 6 }
						});
						return handled;
					}

					phase1(coords) {
						super.phase1(coords);
						this.helpText = 'Plot the terminal point of the vector.';
						gt.updateHelp();
					}
				};
			}
		};
	}
})();
