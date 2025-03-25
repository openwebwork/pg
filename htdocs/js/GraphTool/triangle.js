/* global graphTool, JXG */

(() => {
	if (graphTool && graphTool.triangleTool) return;

	graphTool.triangleTool = {
		Triangle: {
			preInit(gt, point1, point2, point3, solid) {
				for (const point of [point1, point2, point3]) {
					point.setAttribute(gt.definingPointAttributes);
					if (!gt.isStatic) {
						point.on('down', () => gt.onPointDown(point));
						point.on('up', () => gt.onPointUp(point));
					}
				}
				return gt.graphObjectTypes.triangle.createTriangle(point1, point2, point3, solid, gt.color.curve);
			},

			postInit(_gt, point1, point2, point3) {
				this.definingPts.push(point1, point2, point3);
				this.focusPoint = point1;
				this.floodFillUseHasPoint = true;
			},

			blur(gt) {
				this.focused = false;
				for (const obj of this.definingPts) obj.setAttribute({ visible: false });
				for (const b of this.baseObj.borders) b.setAttribute({ strokeColor: gt.color.curve, strokeWidth: 2 });

				gt.updateHelp();
			},

			focus(gt) {
				this.focused = true;
				for (const obj of this.definingPts) obj.setAttribute({ visible: true });
				for (const b of this.baseObj.borders)
					b.setAttribute({ strokeColor: gt.color.focusCurve, strokeWidth: 3 });

				// Focus the currently set point of focus for this object.
				this.focusPoint?.rendNode.focus();

				gt.drawSolid = this.baseObj.borders[0].getAttribute('dash') == 0;
				if (gt.solidButton) gt.solidButton.disabled = gt.drawSolid;
				if (gt.dashedButton) gt.dashedButton.disabled = !gt.drawSolid;

				gt.updateHelp();
			},

			stringify(gt) {
				return [
					this.baseObj.borders[0].getAttribute('dash') === 0 ? 'solid' : 'dashed',
					...this.definingPts.map(
						(point) => `(${gt.snapRound(point.X(), gt.snapSizeX)},${gt.snapRound(point.Y(), gt.snapSizeY)})`
					)
				].join(',');
			},

			fillCmp(_gt, point) {
				const denominator =
					(this.definingPts[1].Y() - this.definingPts[2].Y()) *
						(this.definingPts[0].X() - this.definingPts[2].X()) +
					(this.definingPts[2].X() - this.definingPts[1].X()) *
						(this.definingPts[0].Y() - this.definingPts[2].Y());
				const s =
					((this.definingPts[1].Y() - this.definingPts[2].Y()) * (point[1] - this.definingPts[2].X()) +
						(this.definingPts[2].X() - this.definingPts[1].X()) * (point[2] - this.definingPts[2].Y())) /
					denominator;
				const t =
					((this.definingPts[2].Y() - this.definingPts[0].Y()) * (point[1] - this.definingPts[2].X()) +
						(this.definingPts[0].X() - this.definingPts[2].X()) * (point[2] - this.definingPts[2].Y())) /
					denominator;
				if (s >= 0 && t >= 0 && s + t <= 1) {
					if (s == 0 || t == 0 || s + t == 1) return 0;
					return 1;
				}
				return -1;
			},

			onBoundary(gt, point, aVal, _from) {
				if (this.fillCmp(point) != aVal) return true;

				for (const border of this.baseObj.borders) {
					if (
						Math.abs(JXG.Math.innerProduct(point, border.stdform)) /
							Math.sqrt(border.stdform[1] ** 2 + border.stdform[2] ** 2) <
							0.5 / Math.sqrt(gt.board.unitX * gt.board.unitY) &&
						point[1] > Math.min(border.point1.X(), border.point2.X()) - 0.5 / gt.board.unitX &&
						point[1] < Math.max(border.point1.X(), border.point2.X()) + 0.5 / gt.board.unitX &&
						point[2] > Math.min(border.point1.Y(), border.point2.Y()) - 0.5 / gt.board.unitY &&
						point[2] < Math.max(border.point1.Y(), border.point2.Y()) + 0.5 / gt.board.unitY
					)
						return true;
				}
				return false;
			},

			setSolid(_gt, solid) {
				for (const border of this.baseObj.borders) border.setAttribute({ dash: solid ? 0 : 2 });
			},

			restore(gt, string) {
				let pointData = gt.pointRegexp.exec(string);
				const points = [];
				while (pointData) {
					points.push(pointData.slice(1, 3));
					pointData = gt.pointRegexp.exec(string);
				}
				if (points.length < 3) return false;
				const point1 = gt.graphObjectTypes.triangle.createPoint(
					parseFloat(points[0][0]),
					parseFloat(points[0][1])
				);
				const point2 = gt.graphObjectTypes.triangle.createPoint(
					parseFloat(points[1][0]),
					parseFloat(points[1][1]),
					[point1]
				);
				const point3 = gt.graphObjectTypes.triangle.createPoint(
					parseFloat(points[2][0]),
					parseFloat(points[2][1]),
					[point1, point2]
				);
				return new gt.graphObjectTypes.triangle(point1, point2, point3, /solid/.test(string));
			},

			helperMethods: {
				createTriangle(gt, point1, point2, point3, solid, color) {
					return gt.board.create('polygon', [point1, point2, point3], {
						highlight: false,
						fillOpacity: 0,
						fixed: true,
						borders: {
							strokeWidth: 2,
							highlight: false,
							fixed: true,
							strokeColor: color ? color : gt.color.underConstruction,
							dash: solid ? 0 : 2
						}
					});
				},

				// Prevent a point from being moved off the board by a drag. If one or two other points are provided,
				// then also prevent the point from being moved onto those points or the line between them if there are
				// two.  Note that when this method is called, the point has already been moved by JSXGraph.  Note that
				// this ensures that the graphed object is a triangle, and does not degenerate into a line segment.
				adjustDragPosition(gt, e, point, groupedPoints) {
					const bbox = gt.board.getBoundingBox();

					let x = point.X() < bbox[0] ? bbox[0] : point.X() > bbox[2] ? bbox[2] : point.X();
					let y = point.Y() < bbox[3] ? bbox[3] : point.Y() > bbox[1] ? bbox[1] : point.Y();

					if (
						groupedPoints.length == 1 &&
						Math.abs(x - groupedPoints[0].X()) < JXG.Math.eps &&
						Math.abs(y - groupedPoints[0].Y()) < JXG.Math.eps
					) {
						let xDir = 0,
							yDir = 0;
						// Adjust position of the point if it has the same coordinates as its paired point.
						if (e.type === 'pointermove') {
							const coords = gt.getMouseCoords(e);
							const x_trans = coords.usrCoords[1] - groupedPoints[0].X(),
								y_trans = coords.usrCoords[2] - groupedPoints[0].Y();
							[xDir, yDir] =
								Math.abs(x_trans) < Math.abs(y_trans)
									? [0, y_trans < 0 ? -1 : 1]
									: [x_trans < 0 ? -1 : 1, 0];
						} else if (e.type === 'keydown') {
							xDir = e.key === 'ArrowLeft' ? -1 : e.key === 'ArrowRight' ? 1 : 0;
							yDir = e.key === 'ArrowUp' ? 1 : e.key === 'ArrowDown' ? -1 : 0;
						}
						x += xDir * gt.snapSizeX;
						y += yDir * gt.snapSizeY;
					} else if (
						groupedPoints.length == 2 &&
						gt.graphObjectTypes.triangle.areColinear(x, y, ...groupedPoints)
					) {
						// Adjust the position of the point if it is on the line passing through the two grouped points.
						if (e.type === 'pointermove') {
							const coords = gt.getMouseCoords(e);

							// Of the points to the left of, right of, above, and below the current point, find those
							// that are on the board and not on the line between the two grouped points.
							const points = [
								[x - gt.snapSizeX, y],
								[x + gt.snapSizeX, y],
								[x, y + gt.snapSizeY],
								[x, y - gt.snapSizeY]
							].filter(
								(p) =>
									gt.boardHasPoint(...p) &&
									!gt.graphObjectTypes.triangle.areColinear(...p, ...groupedPoints)
							);

							// Move to the point closest to the mouse cursor.
							let min = -1;
							for (const p of points) {
								const dist = (p[0] - coords.usrCoords[1]) ** 2 + (p[1] - coords.usrCoords[2]) ** 2;
								if (min == -1 || dist < min) {
									min = dist;
									x = p[0];
									y = p[1];
								}
							}
						} else if (e.type === 'keydown') {
							const xDir = e.key === 'ArrowLeft' ? -1 : e.key === 'ArrowRight' ? 1 : 0;
							const yDir = e.key === 'ArrowUp' ? 1 : e.key === 'ArrowDown' ? -1 : 0;
							x += xDir * gt.snapSizeX;
							y += yDir * gt.snapSizeY;
						}
					}

					// If the computed new coordinates are off the board,
					// then move the coordinates the other direction instead.
					if (x < bbox[0]) x = bbox[0] + gt.snapSizeX;
					else if (x > bbox[2]) x = bbox[2] - gt.snapSizeX;
					if (y < bbox[3]) y = bbox[3] + gt.snapSizeY;
					else if (y > bbox[1]) y = bbox[1] - gt.snapSizeY;

					point.setPosition(JXG.COORDS_BY_USER, [x, y]);
				},

				groupedPointDrag(gt, e) {
					gt.graphObjectTypes.triangle.adjustDragPosition(e, this, this.grouped_points);
					gt.setTextCoords(this.X(), this.Y());
					gt.updateObjects();
					gt.updateText();
				},

				createPoint(gt, x, y, grouped_points) {
					const point = gt.board.create(
						'point',
						[gt.snapRound(x, gt.snapSizeX), gt.snapRound(y, gt.snapSizeY)],
						{
							size: 2,
							snapSizeX: gt.snapSizeX,
							snapSizeY: gt.snapSizeY,
							withLabel: false
						}
					);
					point.setAttribute({ snapToGrid: true });

					if (!gt.isStatic) {
						if (typeof grouped_points !== 'undefined' && grouped_points.length) {
							point.grouped_points = [];
							for (const paired_point of grouped_points) {
								point.grouped_points.push(paired_point);
								if (!paired_point.grouped_points) {
									paired_point.grouped_points = [];
									paired_point.on('drag', gt.graphObjectTypes.triangle.groupedPointDrag);
								}
								paired_point.grouped_points.push(point);
								if (
									!paired_point.eventHandlers.drag ||
									paired_point.eventHandlers.drag.every(
										(dragHandler) =>
											dragHandler.handler !== gt.graphObjectTypes.triangle.groupedPointDrag
									)
								)
									paired_point.on('drag', gt.graphObjectTypes.triangle.groupedPointDrag);
							}
							point.on('drag', gt.graphObjectTypes.triangle.groupedPointDrag, point);
						}
					}
					return point;
				},

				// This returns true if the points (x, y), p1, and p2 are colinear.
				areColinear(_gt, x, y, p1, p2) {
					return Math.abs((y - p1.Y()) * (p2.X() - p1.X()) - (p2.Y() - p1.Y()) * (x - p1.X())) < JXG.Math.eps;
				}
			}
		},

		TriangleTool: {
			iconName: 'triangle',
			tooltip: 'Triangle Tool: Graph a triangle.',

			initialize(gt) {
				this.supportsSolidDash = true;

				this.phase1 = (coords) => {
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

					this.helpText = 'Plot two more vertices for the triangle.';
					gt.updateHelp();

					gt.board.on('up', (e) => this.phase2(gt.getMouseCoords(e).usrCoords));

					gt.board.update();
				};

				this.phase2 = (coords) => {
					if (!gt.boardHasPoint(coords[1], coords[2])) return;

					// If the current coordinates are on top of the first point, then use the highlight point
					// coordinates instead.
					if (
						Math.abs(this.point1.X() - gt.snapRound(coords[1], gt.snapSizeX)) < JXG.Math.eps &&
						Math.abs(this.point1.Y() - gt.snapRound(coords[2], gt.snapSizeY)) < JXG.Math.eps
					)
						coords = this.hlObjs.hl_point.coords.usrCoords;

					gt.board.off('up');

					this.point2 = gt.graphObjectTypes.triangle.createPoint(coords[1], coords[2], [this.point1]);
					this.point2.setAttribute({ fixed: true, highlight: false });

					// Get a new x coordinate that is to the right and a new y coordinate that is above, unless that
					// point is off the board.  In that case go left and down instead.
					let newX = this.point2.X() + gt.snapSizeX;
					let newY = this.point2.Y() + gt.snapSizeY;
					if (gt.graphObjectTypes.triangle.areColinear(newX, newY, this.point1, this.point2))
						newX += gt.snapSizeX;

					if (newX > gt.board.getBoundingBox()[2] || newY > gt.board.getBoundingBox()[1]) {
						newX = this.point2.X() - gt.snapSizeX;
						newY = this.point2.Y() - gt.snapSizeY;
						if (gt.graphObjectTypes.triangle.areColinear(newX, newY, this.point1, this.point2))
							newX -= gt.snapSizeX;
					}

					this.updateHighlights(new JXG.Coords(JXG.COORDS_BY_USER, [newX, newY], gt.board));

					this.helpText = 'Plot the last vertex of the triangle.';
					gt.updateHelp();

					gt.board.on('up', (e) => this.phase3(gt.getMouseCoords(e).usrCoords));

					gt.board.update();
				};

				this.phase3 = (coords) => {
					if (!gt.boardHasPoint(coords[1], coords[2])) return;

					// If the current coordinates are on the line through the first and second points,
					// then use the highlight point coordinates instead.
					if (
						gt.graphObjectTypes.triangle.areColinear(
							gt.snapRound(coords[1], gt.snapSizeX),
							gt.snapRound(coords[2], gt.snapSizeY),
							this.point1,
							this.point2
						)
					)
						coords = this.hlObjs.hl_point.coords.usrCoords;

					gt.board.off('up');

					const point3 = gt.graphObjectTypes.triangle.createPoint(coords[1], coords[2], [
						this.point1,
						this.point2
					]);
					gt.selectedObj = new gt.graphObjectTypes.triangle(this.point1, this.point2, point3, gt.drawSolid);
					gt.selectedObj.focusPoint = point3;
					gt.graphedObjs.push(gt.selectedObj);
					delete this.point1;
					delete this.point2;

					this.finish();
				};
			},

			handleKeyEvent(gt, e) {
				if (!this.hlObjs.hl_point || !gt.board.containerObj.contains(document.activeElement)) return;

				if (e.key === 'Enter' || e.key === ' ') {
					e.preventDefault();
					e.stopPropagation();

					if (this.point2) this.phase3(this.hlObjs.hl_point.coords.usrCoords);
					else if (this.point1) this.phase2(this.hlObjs.hl_point.coords.usrCoords);
					else this.phase1(this.hlObjs.hl_point.coords.usrCoords);
				}
			},

			updateHighlights(gt, e) {
				this.hlObjs.hl_line?.setAttribute({ dash: gt.drawSolid ? 0 : 2 });
				for (const border of this.hlObjs.hl_triangle?.borders ?? [])
					border.setAttribute({ dash: gt.drawSolid ? 0 : 2 });
				this.hlObjs.hl_point?.rendNode.focus();

				let coords;
				if (e instanceof MouseEvent && e.type === 'pointermove') {
					coords = gt.getMouseCoords(e);
					this.hlObjs.hl_point?.setPosition(JXG.COORDS_BY_USER, [coords.usrCoords[1], coords.usrCoords[2]]);
				} else if (e instanceof KeyboardEvent && e.type === 'keydown') {
					coords = this.hlObjs.hl_point.coords;
				} else if (e instanceof JXG.Coords) {
					coords = e;
					this.hlObjs.hl_point?.setPosition(JXG.COORDS_BY_USER, [coords.usrCoords[1], coords.usrCoords[2]]);
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

				// Make sure the highlight point is not moved off the board or onto
				// any other points or lines that have already been created.
				if (e instanceof Event) {
					const groupedPoints = [];
					if (this.point1) groupedPoints.push(this.point1);
					if (this.point2) groupedPoints.push(this.point2);
					gt.graphObjectTypes.triangle.adjustDragPosition(e, this.hlObjs.hl_point, groupedPoints);
				}

				if (this.point2 && !this.hlObjs.hl_triangle) {
					// Delete the temporary highlight line if it exists.
					if (this.hlObjs.hl_line) {
						gt.board.removeObject(this.hlObjs.hl_line);
						delete this.hlObjs.hl_line;
					}

					this.hlObjs.hl_triangle = gt.graphObjectTypes.triangle.createTriangle(
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
						dash: gt.drawSolid ? 0 : 2,
						straightFirst: false,
						straightLast: false
					});
				}

				gt.setTextCoords(this.hlObjs.hl_point.X(), this.hlObjs.hl_point.Y());
				gt.board.update();
				return true;
			},

			deactivate(gt) {
				delete this.helpText;
				gt.board.off('up');
				if (this.point1) gt.board.removeObject(this.point1);
				delete this.point1;
				if (this.point2) gt.board.removeObject(this.point2);
				delete this.point2;
				gt.board.containerObj.style.cursor = 'auto';
			},

			activate(gt) {
				gt.board.containerObj.style.cursor = 'none';

				// Draw a highlight point on the board.
				this.updateHighlights(new JXG.Coords(JXG.COORDS_BY_USER, [0, 0], gt.board));

				this.helpText = 'Plot the vertices of the triangle.';
				gt.updateHelp();

				// Wait for the user to select the first point.
				gt.board.on('up', (e) => this.phase1(gt.getMouseCoords(e).usrCoords));
			}
		}
	};
})();
