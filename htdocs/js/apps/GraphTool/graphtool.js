/* global JXG, bootstrap, $ */

'use strict';

window.graphTool = (containerId, options) => {
	// Do nothing if the graph has already been created.
	if (document.getElementById(`${containerId}_graph`)) return;

	const graphContainer = document.getElementById(containerId);
	if (getComputedStyle(graphContainer).width === '0px') {
		setTimeout(() => window.graphTool(containerId, options), 100);
		return;
	}

	const gt = {};

	// Semantic color control

	// dark blue
	// > 13:1 with white
	gt.curveColor = '#0000a6';

	// blue
	// > 9:1 with white
	gt.focusCurveColor = '#0000f5';

	// fillColor must use 6-digit hex
	// medium purple
	// 3:1 with white
	// 4.5:1 with #0000a6
	// > 3:1 with #0000f5
	gt.fillColor  = '#a384e5';

	// strict contrast ratios are less important for these colors
	gt.pointColor = 'orange';
	gt.pointHighlightColor = 'yellow';
	gt.underConstructionColor = 'orange';

	gt.snapSizeX = options.snapSizeX ? options.snapSizeX : 1;
	gt.snapSizeY = options.snapSizeY ? options.snapSizeY : 1;
	gt.isStatic = 'isStatic' in options ? options.isStatic : false;
	const availableTools = options.availableTools ? options.availableTools : [
		'LineTool',
		'CircleTool',
		'VerticalParabolaTool',
		'HorizontalParabolaTool',
		'FillTool',
		'SolidDashTool'
	];

	// These are the icons used for the fill tool and fill graph object.
	gt.fillIcon = "data:image/svg+xml,%3Csvg xmlns:dc='http://purl.org/dc/elements/1.1/' xmlns:cc='http://creativecommons.org/ns%23' xmlns:rdf='http://www.w3.org/1999/02/22-rdf-syntax-ns%23' xmlns:svg='http://www.w3.org/2000/svg' xmlns='http://www.w3.org/2000/svg' id='SVGRoot' version='1.1' viewBox='0 0 32 32' height='32px' width='32px'%3E%3Cdefs id='defs815' /%3E%3Cmetadata id='metadata818'%3E%3Crdf:RDF%3E%3Ccc:Work rdf:about=''%3E%3Cdc:format%3Eimage/svg+xml%3C/dc:format%3E%3Cdc:type rdf:resource='http://purl.org/dc/dcmitype/StillImage' /%3E%3Cdc:title%3E%3C/dc:title%3E%3C/cc:Work%3E%3C/rdf:RDF%3E%3C/metadata%3E%3Cg id='layer1'%3E%3Cpath id='path1382' d='m 13.466084,10.267728 -4.9000003,8.4 4.9000003,4.9 8.4,-4.9 z' style='opacity:1;fill:" + gt.fillColor.replace(/#/, '%23') + ";fill-opacity:1;stroke:%23000000;stroke-width:1.3;stroke-linecap:butt;stroke-linejoin:miter;stroke-opacity:1;stroke-miterlimit:4;stroke-dasharray:none' /%3E%3Cpath id='path1384' d='M 16.266084,15.780798 V 6.273173' style='fill:none;stroke:%23000000;stroke-width:1.38;stroke-linecap:round;stroke-linejoin:miter;stroke-miterlimit:4;stroke-dasharray:none;stroke-opacity:1' /%3E%3Cpath id='path1405' d='m 20,16 c 0,0 2,-1 3,0 1,0 1,1 2,2 0,1 0,2 0,3 0,1 0,2 0,2 0,0 -1,0 -1,0 -1,-1 -1,-1 -1,-2 0,-1 0,-1 -1,-2 0,-1 0,-2 -1,-2 -1,-1 -2,-1 -1,-1 z' style='fill:%230900ff;fill-opacity:1;stroke:%23000000;stroke-width:0.7px;stroke-linecap:butt;stroke-linejoin:miter;stroke-opacity:1' /%3E%3C/g%3E%3C/svg%3E";

	gt.fillIconFocused = "data:image/svg+xml,%3Csvg xmlns:dc='http://purl.org/dc/elements/1.1/' xmlns:cc='http://creativecommons.org/ns%23' xmlns:rdf='http://www.w3.org/1999/02/22-rdf-syntax-ns%23' xmlns:svg='http://www.w3.org/2000/svg' xmlns='http://www.w3.org/2000/svg' id='SVGRoot' version='1.1' viewBox='0 0 32 32' height='32px' width='32px'%3E%3Cdefs id='defs815' /%3E%3Cmetadata id='metadata818'%3E%3Crdf:RDF%3E%3Ccc:Work rdf:about=''%3E%3Cdc:format%3Eimage/svg+xml%3C/dc:format%3E%3Cdc:type rdf:resource='http://purl.org/dc/dcmitype/StillImage' /%3E%3Cdc:title%3E%3C/dc:title%3E%3C/cc:Work%3E%3C/rdf:RDF%3E%3C/metadata%3E%3Cg id='layer1'%3E%3Cpath id='path1382' d='m 13.466084,10.267728 -4.9000003,8.4 4.9000003,4.9 8.4,-4.9 z' style='opacity:1;fill:" + gt.pointHighlightColor.replace(/#/, '%23') + ";fill-opacity:1;stroke:%23000000;stroke-width:1.3;stroke-linecap:butt;stroke-linejoin:miter;stroke-opacity:1;stroke-miterlimit:4;stroke-dasharray:none' /%3E%3Cpath id='path1384' d='M 16.266084,15.780798 V 6.273173' style='fill:none;stroke:%23000000;stroke-width:1.38;stroke-linecap:round;stroke-linejoin:miter;stroke-miterlimit:4;stroke-dasharray:none;stroke-opacity:1' /%3E%3Cpath id='path1405' d='m 20,16 c 0,0 2,-1 3,0 1,0 1,1 2,2 0,1 0,2 0,3 0,1 0,2 0,2 0,0 -1,0 -1,0 -1,-1 -1,-1 -1,-2 0,-1 0,-1 -1,-2 0,-1 0,-2 -1,-2 -1,-1 -2,-1 -1,-1 z' style='fill:%230900ff;fill-opacity:1;stroke:%23000000;stroke-width:0.7px;stroke-linecap:butt;stroke-linejoin:miter;stroke-opacity:1' /%3E%3C/g%3E%3C/svg%3E";

	if ('htmlInputId' in options) gt.html_input = document.getElementById(options.htmlInputId);
	const cfgOptions = {
		showCopyright: false,
		//minimizeReflow: "all",
		pan: { enabled: false },
		zoom: { enabled: false },
		showNavigation: false,
		boundingBox: [-10, 10, 10, -10],
		defaultAxes: {},
		axis: {
			ticks: {
				label: { highlight: false },
				insertTicks: false,
				ticksDistance: 2,
				minorTicks: 1,
				minorHeight: 6,
				majorHeight: 6,
				tickEndings: [1, 1]
			},
			highlight: false,
			firstArrow: { size: 7 },
			lastArrow: { size: 7 },
			straightFirst: false,
			straightLast: false
		},
		grid: { gridX: gt.snapSizeX, gridY: gt.snapSizeY },
	};

	// Deep extend utility function.  This should be good enough for what is needed here.
	const extend = (out, obj) => {
		for (const prop in obj) {
			if (obj.hasOwnProperty(prop)) {
				if (typeof obj[prop] === 'object' && typeof out[prop] === 'object') extend(out[prop], obj[prop]);
				else out[prop] = obj[prop];
			}
		}
	};

	// Merge options that are set by the problem.
	if ('JSXGraphOptions' in options && typeof(options.JSXGraphOptions) === 'object')
		extend(cfgOptions, options.JSXGraphOptions);

	const setupBoard = () => {
		gt.board = JXG.JSXGraph.initBoard(`${containerId}_graph`, cfgOptions);
		gt.board.suspendUpdate();

		// Move the axes defining points to the end so that the arrows go to the board edges.
		const bbox = gt.board.getBoundingBox();
		gt.board.defaultAxes.x.point1.setPosition(JXG.COORDS_BY_USER, [bbox[0], 0]);
		gt.board.defaultAxes.x.point2.setPosition(JXG.COORDS_BY_USER, [bbox[2], 0]);
		gt.board.defaultAxes.y.point1.setPosition(JXG.COORDS_BY_USER, [0, bbox[3]]);
		gt.board.defaultAxes.y.point2.setPosition(JXG.COORDS_BY_USER, [0, bbox[1]]);

		// Add labels to the x and y axes.
		if (options.xAxisLabel) {
			gt.board.create(
				'text',
				[
					() => gt.board.getBoundingBox()[2] - 3 / gt.board.unitX,
					() => 1.5 / gt.board.unitY,
					() => `\\(${options.xAxisLabel}\\)`
				],
				{ anchorX: 'right', anchorY: 'bottom', highlight: false, color: 'black', fixed: true, useMathJax: true }
			);
		}
		if (options.yAxisLabel) {
			gt.board.create(
				'text',
				[
					() => 4.5 / gt.board.unitX,
					() => gt.board.getBoundingBox()[1] + 2.5 / gt.board.unitY,
					() => `\\(${options.yAxisLabel}\\)`
				],
				{ anchorX: 'left', anchorY: 'top', highlight: false, color: 'black', fixed: true, useMathJax: true }
			);
		}

		// Add an empty text that will hold the cursor position.
		gt.current_pos_text = gt.board.create(
			'text',
			[
				() => gt.board.getBoundingBox()[2] - 5 / gt.board.unitX,
				() => gt.board.getBoundingBox()[3] + 5 / gt.board.unitY,
				''
			],
			{ anchorX: 'right', anchorY: 'bottom', fixed: true }
		);

		// Overwrite the popup infobox for points.
		gt.board.highlightInfobox = (x, y, el) => gt.board.highlightCustomInfobox('', el);

		if (!gt.isStatic) {
			gt.board.on('move', (e) => {
				const coords = gt.getMouseCoords(e);
				if (gt.activeTool.updateHighlights(coords)) return;
				if (!gt.selectedObj || !gt.selectedObj.updateTextCoords(coords))
					gt.setTextCoords(coords.usrCoords[1], coords.usrCoords[2]);
			});

			document.addEventListener('keydown', (e) => {
				if (e.key === 'Escape') gt.selectTool.activate();
			});
		}

		window.addEventListener('resize', () => {
			if (gt.board.canvasWidth != graphDiv.offsetWidth - 2 || gt.board.canvasHeight != graphDiv.offsetHeight - 2)
			{
				gt.board.resizeContainer(graphDiv.offsetWidth - 2, graphDiv.offsetHeight - 2, true);
				gt.graphedObjs.forEach((object) => object.onResize());
				gt.staticObjs.forEach((object) => object.onResize());
			}
		});

		gt.drawSolid = true;
		gt.graphedObjs = [];
		gt.staticObjs = [];
		gt.selectedObj = null;

		gt.board.unsuspendUpdate();
	};

	// Some utility functions.
	gt.snapRound = (x, snap) => Math.round(Math.round(x / snap) * snap * 100000) / 100000;

	gt.setTextCoords = options.showCoordinateHints
		? (x, y) => gt.current_pos_text.setText(`(${gt.snapRound(x, gt.snapSizeX)}, ${gt.snapRound(y, gt.snapSizeY)})`)
		: () => {};

	gt.updateText = () => {
		gt.html_input.value = gt.graphedObjs.reduce(
			(val, obj) => `${val}${val.length ? ',' : ''}{${obj.stringify()}}`, ''
		);
	};

	gt.getMouseCoords = (e) => {
		let i;
		if (e[JXG.touchProperty]) { i = 0; }

		const cPos = gt.board.getCoordsTopLeftCorner(),
			absPos = JXG.getPosition(e, i),
			dx = absPos[0] - cPos[0],
			dy = absPos[1] - cPos[1];

		return new JXG.Coords(JXG.COORDS_BY_SCREEN, [dx, dy], gt.board);
	};

	gt.sign = (x) => {
		x = +x;
		if (Math.abs(x) < JXG.Math.eps) { return 0; }
		return x > 0 ? 1 : -1;
	};

	gt.pointRegexp = /\( *(-?[0-9]*(?:\.[0-9]*)?), *(-?[0-9]*(?:\.[0-9]*)?) *\)/g;

	// Prevent paired points from being moved into the same position.  This
	// prevents lines and circles from being made degenerate.
	gt.pairedPointDrag = (point, e) => {
		if (point.X() == point.paired_point.X() && point.Y() == point.paired_point.Y()) {
			const coords = gt.getMouseCoords(e);
			const x_trans = coords.usrCoords[1] - point.paired_point.X(),
				y_trans = coords.usrCoords[2] - point.paired_point.Y();
			if (y_trans > Math.abs(x_trans))
				point.setPosition(JXG.COORDS_BY_USER, [point.X(), point.Y() + gt.snapSizeY]);
			else if (x_trans > Math.abs(y_trans))
				point.setPosition(JXG.COORDS_BY_USER, [point.X() + gt.snapSizeX, point.Y()]);
			else if (x_trans < -Math.abs(y_trans))
				point.setPosition(JXG.COORDS_BY_USER, [point.X() - gt.snapSizeX, point.Y()]);
			else
				point.setPosition(JXG.COORDS_BY_USER, [point.X(), point.Y() - gt.snapSizeY]);
		}
		gt.updateObjects();
		gt.updateText();
	};

	// Prevent paired points from being moved onto the same horizontal or
	// vertical line.  This prevents parabolas from being made degenerate.
	gt.pairedPointDragRestricted = (point, e) => {
		const coords = gt.getMouseCoords(e);
		let new_x = point.X(), new_y = point.Y();
		if (point.X() == point.paired_point.X())
		{
			if (coords.usrCoords[1] > point.paired_point.X()) new_x += gt.snapSizeX;
			else new_x -= gt.snapSizeX;
		}
		if (point.Y() == point.paired_point.Y())
		{
			if (coords.usrCoords[2] > point.paired_point.Y()) new_y += gt.snapSizeX;
			else new_y -= gt.snapSizeX;
		}
		if (point.X() == point.paired_point.X() || point.Y() == point.paired_point.Y())
			point.setPosition(JXG.COORDS_BY_USER, [new_x, new_y]);
		gt.updateObjects();
		gt.updateText();
	};

	gt.createPoint = (x, y, paired_point, restrict) => {
		const point = gt.board.create('point', [x, y],
			{ size: 2, snapToGrid: true, snapSizeX: gt.snapSizeX, snapSizeY: gt.snapSizeY, withLabel: false });
		point.on('down', () => gt.board.containerObj.style.cursor = 'none');
		point.on('up', () => gt.board.containerObj.style.cursor = 'auto');
		if (typeof(paired_point) !== 'undefined') {
			point.paired_point = paired_point;
			paired_point.paired_point = point;
			paired_point.on('drag',
				restrict
					? (e) => gt.pairedPointDragRestricted(paired_point, e)
					: (e) => gt.pairedPointDrag(paired_point, e)
			);
			point.on('drag',
				restrict
					? (e) => gt.pairedPointDragRestricted(point, e)
					: (e) => gt.pairedPointDrag(point, e)
			);
		}
		return point;
	};

	gt.updateObjects = () => {
		gt.graphedObjs.forEach((obj) => obj.update());
		gt.staticObjs.forEach((obj) => obj.update());
	};

	// Generic graph object class from which all the specific graph objects
	// derive.
	class GraphObject {
		constructor(jsxGraphObject) {
			this.baseObj = jsxGraphObject;
			this.definingPts = {};
		}

		blur() {
			Object.values(this.definingPts).forEach((obj) => obj.setAttribute({ visible: false }));
			this.baseObj.setAttribute({ strokeColor: gt.curveColor, strokeWidth: 2 });
		}

		focus() {
			Object.values(this.definingPts).forEach((obj) =>
				obj.setAttribute({
					visible: true, strokeColor: gt.focusCurveColor, strokeWidth: 1, size: 3,
					fillColor: gt.pointColor, highlightStrokeColor: gt.focusCurveColor,
					highlightFillColor: gt.pointHighlightColor
				})
			);
			this.baseObj.setAttribute({ strokeColor: gt.focusCurveColor, strokeWidth: 3 });
			gt.drawSolid = this.baseObj.getAttribute('dash') == 0;
			if ('solidButton' in gt) gt.solidButton.disabled = gt.drawSolid;
			if ('dashedButton' in gt) gt.dashedButton.disabled = !gt.drawSolid;
		}

		update() {}

		fillCmp(/* point */) { return 1; }

		remove() {
			Object.values(this.definingPts).forEach((obj) => gt.board.removeObject(obj));
			gt.board.removeObject(this.baseObj);
		}

		setSolid(solid) { this.baseObj.setAttribute({ dash: solid ? 0 : 2 }); }

		stringify() { return ''; }
		id() { return this.baseObj.id; }
		on(e, handler, context) { this.baseObj.on(e, handler, context); }
		off(e, handler) { this.baseObj.off(e, handler); }
		onResize() {}

		updateTextCoords(coords) {
			return !Object.keys(this.definingPts).every((point) => {
				if (this.definingPts[point].hasPoint(coords.scrCoords[1], coords.scrCoords[2])) {
					gt.setTextCoords(this.definingPts[point].X(), this.definingPts[point].Y());
					return false;
				}
				return true;
			});
		}

		static restore(string) {
			const data = string.match(/^(.*?),(.*)/);
			if (data.length < 3) return false;
			let obj = false;
			Object.keys(gt.graphObjectTypes).every((type) => {
				if (data[1] == gt.graphObjectTypes[type].strId) {
					obj = gt.graphObjectTypes[type].restore(data[2]);
					return false;
				}
				return true;
			});
			if (obj !== false) obj.blur();
			return obj;
		}
	}

	// Line graph object
	class Line extends GraphObject {
		static strId = 'line';

		constructor(point1, point2, solid, color) {
			super(gt.board.create('line', [point1, point2], {
				fixed: true, highlight: false, strokeColor: color ? color : gt.underConstructionColor,
				dash: solid ? 0 : 2
			}));
			this.definingPts.point1 = point1;
			this.definingPts.point2 = point2;
		}

		stringify() {
			return [
				Line.strId, this.baseObj.getAttribute('dash') == 0 ? 'solid' : 'dashed',
				'(' + gt.snapRound(this.definingPts.point1.X(), gt.snapSizeX) + ',' +
				gt.snapRound(this.definingPts.point1.Y(), gt.snapSizeY) + ')',
				'(' + gt.snapRound(this.definingPts.point2.X(), gt.snapSizeX) + ',' +
				gt.snapRound(this.definingPts.point2.Y(), gt.snapSizeY) + ')'
			].join(',');
		}

		fillCmp(point) {
			return gt.sign(JXG.Math.innerProduct(point, this.baseObj.stdform));
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
			return new gt.graphObjectTypes.line(point1, point2, /solid/.test(string), gt.curveColor);
		}
	}

	// Circle graph object
	class Circle extends GraphObject {
		static strId = 'circle';

		constructor(center, point, solid, color) {
			super(gt.board.create('circle', [center, point], {
				fixed: true, highlight: false, strokeColor: color ? color : gt.underConstructionColor,
				dash: solid ? 0 : 2
			}));
			this.definingPts.center = center;
			this.definingPts.point = point;
		}

		stringify() {
			return [
				Circle.strId, (this.baseObj.getAttribute('dash') == 0 ? 'solid' : 'dashed'),
				'(' + gt.snapRound(this.definingPts.center.X(), gt.snapSizeX) + ',' +
				gt.snapRound(this.definingPts.center.Y(), gt.snapSizeY) + ')',
				'(' + gt.snapRound(this.definingPts.point.X(), gt.snapSizeX) + ',' +
				gt.snapRound(this.definingPts.point.Y(), gt.snapSizeY) + ')'
			].join(',');
		}

		fillCmp(point) {
			return gt.sign(this.baseObj.stdform[3] *
				(point[1] * point[1] + point[2] * point[2])
				+ JXG.Math.innerProduct(point, this.baseObj.stdform));
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
			return new gt.graphObjectTypes.circle(center, point, /solid/.test(string), gt.curveColor);
		}
	}

	// Parabola graph object.
	// The underlying jsxgraph object is really a curve.  The problem with the
	// jsxgraph parabola object is that it can not be created from the vertex
	// and a point on the graph of the parabola.
	const aVal = (vertex, point, vertical) =>
		vertical
			? (point.Y() - vertex.Y()) / Math.pow(point.X() - vertex.X(), 2)
			: (point.X() - vertex.X()) / Math.pow(point.Y() - vertex.Y(), 2);

	const createParabola = (vertex, point, vertical, solid, color) => {
		if (vertical) return gt.board.create('curve', [
			// x and y coordinates of point on curve
			(x) => x, (x) => aVal(vertex, point, vertical) * Math.pow(x - vertex.X(), 2) + vertex.Y(),
			// domain minimum and maximum
			() => gt.board.getBoundingBox()[0], () => gt.board.getBoundingBox()[2]
		], {
			strokeWidth: 2, highlight: false, strokeColor: color ? color : gt.underConstructionColor,
			dash: solid ? 0 : 2
		});
		else return gt.board.create('curve', [
			// x and y coordinate of point on curve
			(x) => aVal(vertex, point, vertical) * Math.pow(x - vertex.Y(), 2) + vertex.X(), (x) => x,
			// domain minimum and maximum
			() => gt.board.getBoundingBox()[3], () => gt.board.getBoundingBox()[1]
		], {
			strokeWidth: 2, highlight: false, strokeColor: color ? color : gt.underConstructionColor,
			dash: solid ? 0 : 2
		});
	};

	class Parabola extends GraphObject {
		static strId = 'parabola';

		constructor(vertex, point, vertical, solid, color) {
			super(createParabola(vertex, point, vertical, solid, color));
			this.definingPts.vertex = vertex;
			this.definingPts.point = point;
			this.vertical = vertical;
		}

		stringify() {
			return [
				Parabola.strId, this.baseObj.getAttribute('dash') == 0 ? 'solid' : 'dashed',
				this.vertical ? 'vertical' : 'horizontal',
				'(' + gt.snapRound(this.definingPts.vertex.X(), gt.snapSizeX) + ',' +
				gt.snapRound(this.definingPts.vertex.Y(), gt.snapSizeY) + ')',
				'(' + gt.snapRound(this.definingPts.point.X(), gt.snapSizeX) + ',' +
				gt.snapRound(this.definingPts.point.Y(), gt.snapSizeY) + ')'
			].join(',');
		}

		fillCmp(point) {
			if (this.vertical)
				return gt.sign(point[2] - this.baseObj.Y(point[1]));
			else
				return gt.sign(point[1] - this.baseObj.X(point[2]));
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
			return new gt.graphObjectTypes.parabola(vertex, point,
				/vertical/.test(string), /solid/.test(string), gt.curveColor);
		}
	}

	// Fill graph object
	class Fill extends GraphObject {
		static strId = 'fill';

		constructor(point) {
			point.setAttribute({ visible: false });
			super(point);
			this.focused = true;
			this.definingPts.point = point;
			this.updateTimeout = 0;
			this.update();

			// The snapToGrid option does not allow centering an image on a point.
			// The following implements a snap to grid method that does allow that.
			this.definingPts.icon = gt.board.create(
				'image',
				[
					() => this.focused ? gt.fillIconFocused : gt.fillIcon,
					[point.X() - 12 / gt.board.unitX, point.Y() - 12 / gt.board.unitY],
					[() => 24 / gt.board.unitX, () => 24 / gt.board.unitY]
				],
				{ withLabel: false, highlight: false, layer: 9, name: 'FillIcon' }
			);

			this.definingPts.icon.point = point;
			this.isStatic = gt.isStatic;
			if (!gt.isStatic)
			{
				this.on('down', () => gt.board.containerObj.style.cursor = 'none');
				this.on('up', () => gt.board.containerObj.style.cursor = 'auto');
				this.on('drag', (e) => {
					const coords = gt.getMouseCoords(e);
					const x = gt.snapRound(coords.usrCoords[1], gt.snapSizeX),
						y = gt.snapRound(coords.usrCoords[2], gt.snapSizeY);
					this.definingPts.icon.setPosition(JXG.COORDS_BY_USER,
						[x - 12 / gt.board.unitX, y - 12 / gt.board.unitY]);
					point.setPosition(JXG.COORDS_BY_USER, [x, y]);
					this.update();
					gt.updateText();
				});
			}
		}

		// The fill object has a non-standard focus object.  So focus/blur and
		// on/off methods need to be overridden.
		blur() {
			this.focused = false;
			this.definingPts.icon.setAttribute({ fixed: true });
		}

		focus() {
			this.focused = true;
			this.definingPts.icon.setAttribute({ fixed: false });
		}

		on(e, handler, context) { this.definingPts.icon.on(e, handler, context); }
		off(e, handler) { this.definingPts.icon.off(e, handler); }

		remove() {
			if ('fillObj' in this) gt.board.removeObject(this.fillObj);
			super.remove();
		}

		update() {
			if (this.isStatic) return;
			if (this.updateTimeout) clearTimeout(this.updateTimeout);
			this.updateTimeout = setTimeout(() => {
				this.updateTimeout = 0;
				if ('fillObj' in this) {
					gt.board.removeObject(this.fillObj);
					delete this.fillObj;
				}

				const centerPt = this.definingPts.point.coords.usrCoords;
				const allObjects = gt.graphedObjs.concat(gt.staticObjs);

				// Determine which side of each object needs to be shaded.  If the point
				// is on a graphed object, then don't fill.
				const a_vals = Array(allObjects.length);
				for (let i = 0; i < allObjects.length; ++i) {
					a_vals[i] = allObjects[i].fillCmp(centerPt);
					if (a_vals[i] == 0) return;
				}

				const canvas = document.createElement('canvas');
				canvas.width = gt.board.canvasWidth;
				canvas.height = gt.board.canvasHeight;
				const context = canvas.getContext('2d');
				const colorLayerData = context.getImageData(0, 0, canvas.width, canvas.height);

				const fillPixel = (pixelPos) => {
					colorLayerData.data[pixelPos] = Number('0x' + gt.fillColor.slice(1, 3));
					colorLayerData.data[pixelPos + 1] = Number('0x' + gt.fillColor.slice(3, 5));
					colorLayerData.data[pixelPos + 2] = Number('0x' + gt.fillColor.slice(5));
					colorLayerData.data[pixelPos + 3] = 255;
				};

				const isFillPixel = (x, y) => {
					const curPixel = [1.0, (x - gt.board.origin.scrCoords[1]) / gt.board.unitX,
						(gt.board.origin.scrCoords[2] - y) / gt.board.unitY];
					for (let i = 0; i < allObjects.length; ++i) {
						if (allObjects[i].fillCmp(curPixel) != a_vals[i])
							return false;
					}
					return true;
				};

				for (let j = 0; j < canvas.width; ++j) {
					for (let k = 0; k < canvas.height; ++k) {
						if (isFillPixel(j, k)) fillPixel((k * canvas.width + j) * 4);
					}
				}

				context.putImageData(colorLayerData, 0, 0);
				const dataURL = canvas.toDataURL('image/png');
				canvas.remove();

				const boundingBox = gt.board.getBoundingBox();
				this.fillObj = gt.board.create('image', [
					dataURL,
					[boundingBox[0], boundingBox[3]],
					[boundingBox[2] - boundingBox[0], boundingBox[1] - boundingBox[3]]
				], { withLabel: false, highlight: false, fixed: true, layer: 0 });

			}, 100);
		}

		onResize() {
			this.definingPts.icon.setPosition(JXG.COORDS_BY_USER,
				[this.definingPts.point.X() - 12 / gt.board.unitX,
					this.definingPts.point.Y() - 12 / gt.board.unitY]);
			gt.board.update();
		}

		updateTextCoords(coords) {
			if (this.definingPts.point.hasPoint(coords.scrCoords[1], coords.scrCoords[2])) {
				gt.setTextCoords(this.definingPts.point.X(), this.definingPts.point.Y());
				return true;
			}
			return false;
		}

		stringify() {
			return [
				Fill.strId,
				'(' + gt.snapRound(this.baseObj.X(), gt.snapSizeX) + ',' +
				gt.snapRound(this.baseObj.Y(), gt.snapSizeY) + ')'
			].join(',');
		}

		static restore(string) {
			let pointData = gt.pointRegexp.exec(string);
			const points = [];
			while (pointData) {
				points.push(pointData.slice(1, 3));
				pointData = gt.pointRegexp.exec(string);
			}
			if (!points.length) return false;
			return new gt.graphObjectTypes.fill(gt.createPoint(parseFloat(points[0][0]), parseFloat(points[0][1])));
		}
	}

	gt.graphObjectTypes = {};
	gt.graphObjectTypes[Line.strId] = Line;
	gt.graphObjectTypes[Parabola.strId] = Parabola;
	gt.graphObjectTypes[Circle.strId] = Circle;
	gt.graphObjectTypes[Fill.strId] = Fill;

	// Load any custom graph objects.
	if ('customGraphObjects' in options) {
		Object.keys(options.customGraphObjects).forEach((name) => {
			const graphObject = options.customGraphObjects[name];
			const parentObject = 'parent' in graphObject ?
				(graphObject.parent ? gt.graphObjectTypes[graphObject.parent] : null) : GraphObject;

			const customGraphObject = class extends parentObject {
				static strId = name;

				constructor(...args) {
					if (parentObject) {
						if ('preInit' in graphObject) super(graphObject.preInit.apply(null, [gt, ...args]));
						else super(...args);

						if ('postInit' in graphObject) graphObject.postInit.apply(this, [gt, ...args]);
					} else {
						const that = Object.create(new.target.prototype);
						// The preInit method is required if not deriving from another class.  It is essentially the
						// constructor in this case.  Furthermore, there is no need for a postInit method as everything
						// can be done in the preInit method.
						graphObject.preInit.apply(that, [gt, ...args]);
						return that;
					}
				}

				blur() {
					if ((!('blur' in graphObject) || graphObject.blur.call(this, gt)) && parentObject) super.blur();
				}

				focus() {
					if ((!('focus' in graphObject) || graphObject.focus.call(this, gt)) && parentObject) super.focus();
				}

				update() {
					if ('update' in graphObject) graphObject.update.call(this, gt);
					else if (parentObject) super.update();
				}

				onResize() {
					if ('onResize' in graphObject) graphObject.onResize.call(this, gt);
					else if (parentObject) super.onResize();
				}

				updateTextCoords(coords) {
					if ('updateTextCoords' in graphObject) return graphObject.updateTextCoords.call(this, gt, coords);
					else if (parentObject) return super.updateTextCoords(coords);
					return false;
				}

				fillCmp(point) {
					if ('fillCmp' in graphObject) return graphObject.fillCmp.call(this, gt, point);
					else if (parentObject) return super.fillCmp(point);
					return 1;
				}

				remove() {
					if ('remove' in graphObject) graphObject.remove.call(this, gt);
					if (parentObject) super.remove();
				}

				setSolid(solid) {
					if ('setSolid' in graphObject) graphObject.setSolid.call(this, gt, solid);
					else if (parentObject) super.setSolid(solid);
				}

				on(e, handler, context) {
					if ('on' in graphObject) graphObject.on.call(this, e, handler, context);
					else if (parentObject) super.on(e, handler, context);
				}

				off(e, handler) {
					if ('off' in graphObject) graphObject.off.call(this, e, handler);
					else if (parentObject) super.off(e, handler);
				}

				stringify() {
					if ('stringify' in graphObject)
							return [customGraphObject.strId, graphObject.stringify.call(this, gt)].join(',');
					else if (parentObject) return super.stringify();
					return '';
				}

				static restore(string) {
					if ('restore' in graphObject) return graphObject.restore.call(this, gt, string);
					else if (parentObject) return super.restore(string);
					return false;
				}
			};

			if ('helperMethods' in graphObject) {
				Object.keys(graphObject.helperMethods).forEach((method) => {
					customGraphObject[method] = function(...args) {
						return graphObject.helperMethods[method].apply(this, [gt, ...args]);
					};
				});
			}

			gt.graphObjectTypes[customGraphObject.strId] = customGraphObject;
		});
	}

	// Generic tool class from which all the graphing tools derive.  Most of the methods, if overridden, must call the
	// corresponding generic method.  At this point the updateHighlights method is the only one that this doesn't need
	// to be done with.
	class GenericTool {
		constructor(container, name, tooltip) {
			const div = document.createElement('div');
			div.classList.add('gt-button-div');
			div.dataset.bsToggle = 'tooltip';
			div.title = tooltip;
			this.button = document.createElement('button');
			this.button.type = 'button';
			this.button.classList.add('btn', 'btn-light', 'gt-button', 'gt-tool-button', 'gt-' + name + '-tool');
			this.button.addEventListener('click', () => this.activate());
			div.append(this.button);
			container.append(div);
			this.hlObjs = {};
		}

		activate() {
			gt.activeTool.deactivate();
			gt.activeTool = this;
			this.button.blur();
			this.button.disabled = true;
			if (gt.selectedObj) { gt.selectedObj.blur(); }
			gt.selectedObj = null;
		}

		finish() {
			gt.updateObjects();
			gt.updateText();
			gt.board.update();
			gt.selectTool.activate();
		}

		updateHighlights(/* coords */) { return false; }

		removeHighlights() {
			for (const obj in this.hlObjs) {
				gt.board.removeObject(this.hlObjs[obj]);
				delete this.hlObjs[obj];
			}
		}

		deactivate() {
			this.button.disabled = false;
			this.removeHighlights();
		}
	}

	// Select tool
	class SelectTool extends GenericTool {
		constructor(container) {
			super(container, 'select', 'Object Selection Tool');
		}

		activate(initialize) {
			// Cache the currently selected object to re-select after the GenericTool
			// activate method de-selects it.
			const selectedObj = gt.selectedObj;

			super.activate();
			if (selectedObj) gt.selectedObj = selectedObj;

			// If only one object has been graphed, select it.
			if (!initialize && gt.graphedObjs.length == 1) gt.selectedObj = gt.graphedObjs[0];

			if (gt.selectedObj) { gt.selectedObj.focus(); }

			for (const obj of gt.graphedObjs) {
				obj.selectionChangedHandler = (e) => {
					if (gt.selectedObj) {
						if (gt.selectedObj.id() != obj.id()) {
							// Don't allow the selection of a new object if the pointer
							// is in the vicinity of one of the currently selected
							// object's defining points.
							const coords = gt.getMouseCoords(e);
							for (const point of Object.values(gt.selectedObj.definingPts)) {
								if (point.X() == gt.snapRound(coords.usrCoords[1], gt.snapSizeX)
									&& point.Y() == gt.snapRound(coords.usrCoords[2], gt.snapSizeY))
									return;
							}
							gt.selectedObj.blur();
						} else
							return;
					}
					gt.selectedObj = obj;
					gt.selectedObj.focus();
				};
				obj.on('down', obj.selectionChangedHandler);
			}
		}

		deactivate() {
			for (const obj of gt.graphedObjs) {
				obj.off('down', obj.selectionChangedHandler);
				delete obj.selectionChangedHandler;
			}

			super.deactivate();
		}
	}

	// Line graphing tool
	class LineTool extends GenericTool {
		constructor(container, iconName, tooltip) {
			super(container, iconName ? iconName : 'line', tooltip ? tooltip : 'Line Tool');
		}

		updateHighlights(coords) {
			if ('hl_line' in this.hlObjs) this.hlObjs.hl_line.setAttribute({ dash: gt.drawSolid ? 0 : 2 });
			if (typeof(coords) === 'undefined') return false;
			if ('point1' in this && gt.snapRound(coords.usrCoords[1], gt.snapSizeX) == this.point1.X() &&
				gt.snapRound(coords.usrCoords[2], gt.snapSizeY) == this.point1.Y())
				return false;
			if (!('hl_point' in this.hlObjs)) {
				this.hlObjs.hl_point = gt.board.create('point', [coords.usrCoords[1], coords.usrCoords[2]], {
					size: 2, color: gt.underConstructionColor, snapToGrid: true,
					snapSizeX: gt.snapSizeX, snapSizeY: gt.snapSizeY, withLabel: false
				});
				if ('point1' in this)
					this.hlObjs.hl_line = gt.board.create('line', [this.point1, this.hlObjs.hl_point], {
						fixed: true, strokeColor: gt.underConstructionColor, highlight: false,
						dash: gt.drawSolid ? 0 : 2
					});
			} else
				this.hlObjs.hl_point.setPosition(JXG.COORDS_BY_USER, [coords.usrCoords[1], coords.usrCoords[2]]);

			gt.setTextCoords(this.hlObjs.hl_point.X(), this.hlObjs.hl_point.Y());
			gt.board.update();
			return true;
		}

		deactivate() {
			gt.board.off('up');
			if ('point1' in this) gt.board.removeObject(this.point1);
			delete this.point1;
			gt.board.containerObj.style.cursor = 'auto';
			super.deactivate();
		}

		activate() {
			super.activate();
			gt.board.containerObj.style.cursor = 'none';

			gt.board.on('up', (e) => {
				const coords = gt.getMouseCoords(e);
				// Don't allow the point to be created off the board.
				if (!gt.board.hasPoint(coords.usrCoords[1], coords.usrCoords[2])) return;
				gt.board.off('up');
				this.point1 = gt.board.create('point', [coords.usrCoords[1], coords.usrCoords[2]],
					{ size: 2, snapToGrid: true, snapSizeX: gt.snapSizeX, snapSizeY: gt.snapSizeY, withLabel: false });
				this.point1.setAttribute({ fixed: true });
				this.removeHighlights();

				gt.board.on('up', (e) => {
					const coords = gt.getMouseCoords(e);

					// Don't allow the second point to be created on top of the first or off the board
					if ((this.point1.X() == gt.snapRound(coords.usrCoords[1], gt.snapSizeX) &&
						this.point1.Y() == gt.snapRound(coords.usrCoords[2], gt.snapSizeY)) ||
						!gt.board.hasPoint(coords.usrCoords[1], coords.usrCoords[2]))
						return;
					gt.board.off('up');

					this.point1.setAttribute({ fixed: false });
					this.point1.on('down', () => gt.board.containerObj.style.cursor = 'none');
					this.point1.on('up', () => gt.board.containerObj.style.cursor = 'auto');

					gt.selectedObj = new gt.graphObjectTypes.line(this.point1,
						gt.createPoint(coords.usrCoords[1], coords.usrCoords[2], this.point1),
						gt.drawSolid);
					gt.graphedObjs.push(gt.selectedObj);
					delete this.point1;

					this.finish();
				});

				gt.board.update();
			});
		}
	}

	// Circle graphing tool
	class CircleTool extends GenericTool {
		constructor(container, iconName, tooltip) {
			super(container, iconName ? iconName : 'circle', tooltip ? tooltip : 'Circle Tool');
		}

		updateHighlights(coords) {
			if ('hl_circle' in this.hlObjs) this.hlObjs.hl_circle.setAttribute({ dash: gt.drawSolid ? 0 : 2 });
			if (typeof(coords) === 'undefined') return false;
			if ('center' in this && gt.snapRound(coords.usrCoords[1], gt.snapSizeX) == this.center.X() &&
				gt.snapRound(coords.usrCoords[2], gt.snapSizeY) == this.center.Y())
				return false;
			if (!('hl_point' in this.hlObjs)) {
				this.hlObjs.hl_point = gt.board.create('point', [coords.usrCoords[1], coords.usrCoords[2]], {
					size: 2, color: gt.underConstructionColor, snapToGrid: true,
					snapSizeX: gt.snapSizeX, snapSizeY: gt.snapSizeY, withLabel: false
				});
				if ('center' in this)
					this.hlObjs.hl_circle = gt.board.create('circle', [this.center, this.hlObjs.hl_point], {
						fixed: true, strokeColor: gt.underConstructionColor, highlight: false,
						dash: gt.drawSolid ? 0 : 2
					});
			} else
				this.hlObjs.hl_point.setPosition(JXG.COORDS_BY_USER, [coords.usrCoords[1], coords.usrCoords[2]]);

			gt.setTextCoords(this.hlObjs.hl_point.X(), this.hlObjs.hl_point.Y());
			gt.board.update();
			return true;
		}

		deactivate() {
			gt.board.off('up');
			if ('center' in this) gt.board.removeObject(this.center);
			delete this.center;
			gt.board.containerObj.style.cursor = 'auto';
			super.deactivate();
		}

		activate() {
			super.activate();
			gt.board.containerObj.style.cursor = 'none';

			gt.board.on('up', (e) => {
				const coords = gt.getMouseCoords(e);
				// Don't allow the point to be created off the board.
				if (!gt.board.hasPoint(coords.usrCoords[1], coords.usrCoords[2])) return;
				gt.board.off('up');
				this.center = gt.board.create('point', [coords.usrCoords[1], coords.usrCoords[2]],
					{ size: 2, snapToGrid: true, snapSizeX: gt.snapSizeX, snapSizeY: gt.snapSizeY, withLabel: false });
				this.center.setAttribute({ fixed: true });
				this.removeHighlights();

				gt.board.on('up', (e) => {
					const coords = gt.getMouseCoords(e);

					// Don't allow the second point to be created on top of the center or off the board
					if ((this.center.X() == gt.snapRound(coords.usrCoords[1], gt.snapSizeX) &&
						this.center.Y() == gt.snapRound(coords.usrCoords[2], gt.snapSizeY)) ||
						!gt.board.hasPoint(coords.usrCoords[1], coords.usrCoords[2]))
						return;
					gt.board.off('up');

					this.center.setAttribute({ fixed: false });
					this.center.on('down', () => gt.board.containerObj.style.cursor = 'none');
					this.center.on('up', () => gt.board.containerObj.style.cursor = 'auto');

					gt.selectedObj = new gt.graphObjectTypes.circle(this.center,
						gt.createPoint(coords.usrCoords[1], coords.usrCoords[2], this.center),
						gt.drawSolid);
					gt.graphedObjs.push(gt.selectedObj);
					delete this.center;

					this.finish();
				});

				gt.board.update();
			});
		}
	}

	// Parabola graphing tool
	class ParabolaTool extends GenericTool {
		constructor(container, vertical, iconName, tooltip) {
			super(container,
				iconName ? iconName : (vertical ? 'vertical-parabola' : 'horizontal-parabola'),
				tooltip ? tooltip : (vertical ? 'Vertical Parabola Tool' : 'Horizontal Parabola Tool'));
			this.vertical = vertical;
		}

		updateHighlights(coords) {
			if ('hl_parabola' in this.hlObjs) this.hlObjs.hl_parabola.setAttribute({ dash: gt.drawSolid ? 0 : 2 });
			if (typeof(coords) === 'undefined') return false;
			if ('vertex' in this &&
				(gt.snapRound(coords.usrCoords[1], gt.snapSizeX) == this.vertex.X() ||
					gt.snapRound(coords.usrCoords[2], gt.snapSizeY) == this.vertex.Y()))
				return false;
			if (!('hl_point' in this.hlObjs)) {
				this.hlObjs.hl_point = gt.board.create('point', [coords.usrCoords[1], coords.usrCoords[2]], {
					size: 2, color: gt.underConstructionColor, snapToGrid: true,
					snapSizeX: gt.snapSizeX, snapSizeY: gt.snapSizeY,
					highlight: false, withLabel: false
				});
				if ('vertex' in this)
					this.hlObjs.hl_parabola = createParabola(this.vertex, this.hlObjs.hl_point, this.vertical,
						gt.drawSolid, gt.underConstructionColor);
			} else
				this.hlObjs.hl_point.setPosition(JXG.COORDS_BY_USER, [coords.usrCoords[1], coords.usrCoords[2]]);

			gt.setTextCoords(this.hlObjs.hl_point.X(), this.hlObjs.hl_point.Y());
			gt.board.update();
			return true;
		}

		deactivate() {
			gt.board.off('up');
			if ('vertex' in this) gt.board.removeObject(this.vertex);
			delete this.vertex;
			gt.board.containerObj.style.cursor = 'auto';
			super.deactivate();
		}

		activate() {
			super.activate();
			gt.board.containerObj.style.cursor = 'none';

			gt.board.on('up', (e) => {
				const coords = gt.getMouseCoords(e);
				// Don't allow the point to be created off the board.
				if (!gt.board.hasPoint(coords.usrCoords[1], coords.usrCoords[2])) return;
				gt.board.off('up');
				this.vertex = gt.board.create('point', [coords.usrCoords[1], coords.usrCoords[2]],
					{ size: 2, snapToGrid: true, snapSizeX: gt.snapSizeX, snapSizeY: gt.snapSizeY, withLabel: false });
				this.vertex.setAttribute({ fixed: true });
				this.removeHighlights();

				gt.board.on('up', (e) => {
					const coords = gt.getMouseCoords(e);

					// Don't allow the second point to be created on the same
					// horizontal or vertical line as the vertex or off the board.
					if ((this.vertex.X() == gt.snapRound(coords.usrCoords[1], gt.snapSizeX) ||
						this.vertex.Y() == gt.snapRound(coords.usrCoords[2], gt.snapSizeY)) ||
						!gt.board.hasPoint(coords.usrCoords[1], coords.usrCoords[2]))
						return;

					gt.board.off('up');

					this.vertex.setAttribute({ fixed: false });
					this.vertex.on('down', () => gt.board.containerObj.style.cursor = 'none');
					this.vertex.on('up', () => gt.board.containerObj.style.cursor = 'auto');

					gt.selectedObj = new gt.graphObjectTypes.parabola(this.vertex,
						gt.createPoint(coords.usrCoords[1], coords.usrCoords[2], this.vertex, true),
						this.vertical, gt.drawSolid);
					gt.graphedObjs.push(gt.selectedObj);
					delete this.vertex;

					this.finish();
				});

				gt.board.update();
			});
		}
	}

	class VerticalParabolaTool extends ParabolaTool {
		constructor(container, iconName, tooltip) {
			super(container, true, iconName, tooltip);
		}
	}

	class HorizontalParabolaTool extends ParabolaTool {
		constructor(container, iconName, tooltip) {
			super(container, false, iconName, tooltip);
		}
	}

	// Fill tool
	class FillTool extends GenericTool {
		constructor(container, iconName, tooltip) {
			super(container, iconName ? iconName : 'fill', tooltip ? tooltip : 'Region Shading Tool');
		}

		updateHighlights(coords) {
			if (typeof(coords) === 'undefined') return false;
			if (!('hl_point' in this.hlObjs)) {
				this.hlObjs.hl_point = gt.board.create('image', [
					gt.fillIcon, [
						gt.snapRound(coords.usrCoords[1], gt.snapSizeX) - 12 / gt.board.unitX,
						gt.snapRound(coords.usrCoords[2], gt.snapSizeY) - 12 / gt.board.unitY
					], [24 / gt.board.unitX, 24 / gt.board.unitY]
				], { withLabel: false, highlight: false, layer: 9 });
			} else
				this.hlObjs.hl_point.setPosition(JXG.COORDS_BY_USER, [
					gt.snapRound(coords.usrCoords[1], gt.snapSizeX) - 12 / gt.board.unitX,
					gt.snapRound(coords.usrCoords[2], gt.snapSizeY) - 12 / gt.board.unitY
				]);

			gt.setTextCoords(coords.usrCoords[1], coords.usrCoords[2]);
			gt.board.update();
			return true;
		}

		deactivate() {
			gt.board.off('up');
			gt.board.containerObj.style.cursor = 'auto';
			super.deactivate();
		}

		activate() {
			super.activate();
			gt.board.containerObj.style.cursor = 'none';
			gt.board.on('up', (e) => {
				gt.board.off('up');
				const coords = gt.getMouseCoords(e);

				// Don't allow the fill to be created off the board
				if (!gt.board.hasPoint(coords.usrCoords[1], coords.usrCoords[2])) return;
				gt.board.off('up');

				gt.selectedObj = new gt.graphObjectTypes.fill(gt.createPoint(coords.usrCoords[1], coords.usrCoords[2]));
				gt.graphedObjs.push(gt.selectedObj);

				gt.updateText();
				gt.board.update();
				gt.selectTool.activate();
			});
		}
	}

	// Draw objects solid or dashed. Makes the currently selected object (if
	// any) solid or dashed, and anything drawn while the tool is selected will
	// be drawn solid or dashed.
	const toggleSolidity = (button, drawSolid) => {
		button.blur();
		if ('solidButton' in gt) gt.solidButton.disabled = drawSolid;
		if ('dashedButton' in gt) gt.dashedButton.disabled = !drawSolid;
		if (gt.selectedObj)
		{
			gt.selectedObj.setSolid(drawSolid);
			gt.updateText();
		}
		gt.drawSolid = drawSolid;
		gt.activeTool.updateHighlights();
	};

	class SolidDashTool {
		constructor(container) {
			const solidDashBox = document.createElement('div');
			solidDashBox.classList.add('gt-solid-dash-box');
			// The draw solid button is active by default.
			const solidButtonDiv = document.createElement('div');
			solidButtonDiv.classList.add('gt-button-div', 'gt-solid-button-div');
			solidButtonDiv.dataset.bsToggle = 'tooltip';
			solidButtonDiv.title = 'Make Selected Object Solid';
			gt.solidButton = document.createElement('button');
			gt.solidButton.classList.add('btn', 'btn-light', 'gt-button', 'gt-tool-button', 'gt-solid-tool');
			gt.solidButton.type = 'button';
			gt.solidButton.disabled = true;
			gt.solidButton.addEventListener('click', () => toggleSolidity(gt.solidButton, true));
			solidButtonDiv.append(gt.solidButton);
			solidDashBox.append(solidButtonDiv);

			const dashedButtonDiv = document.createElement('div');
			dashedButtonDiv.classList.add('gt-button-div', 'gt-dashed-button-div');
			dashedButtonDiv.dataset.bsToggle = 'tooltip';
			dashedButtonDiv.title = 'Make Selected Object Dashed';
			gt.dashedButton = document.createElement('button');
			gt.dashedButton.classList.add('btn', 'btn-light', 'gt-button', 'gt-tool-button', 'gt-dashed-tool');
			gt.dashedButton.type = 'button';
			gt.dashedButton.addEventListener('click', () => toggleSolidity(gt.dashedButton, false));
			dashedButtonDiv.append(gt.dashedButton);
			solidDashBox.append(dashedButtonDiv);
			container.append(solidDashBox);
		}
	}

	gt.toolTypes = {
		LineTool: LineTool,
		CircleTool: CircleTool,
		VerticalParabolaTool: VerticalParabolaTool,
		HorizontalParabolaTool: HorizontalParabolaTool,
		FillTool: FillTool,
		SolidDashTool: SolidDashTool
	};

	// Create the tools and html elements.
	const graphDiv = document.createElement('div');
	graphDiv.id = `${containerId}_graph`;
	graphDiv.classList.add('jxgbox', 'graphtool-graph');
	graphContainer.append(graphDiv);

	if (!gt.isStatic) {
		const buttonBox = document.createElement('div');
		buttonBox.classList.add('gt-toolbar-container');
		gt.selectTool = new SelectTool(buttonBox);

		// Load any custom tools.
		if ('customTools' in options) {
			Object.keys(options.customTools).forEach((tool) => {
				const toolObject = options.customTools[tool];
				const parentTool = 'parent' in toolObject ?
					(toolObject.parent ? gt.toolTypes[toolObject.parent] : null) : GenericTool;
				const customTool = class extends parentTool {
					constructor(container) {
						if (parentTool) {
							super(container, toolObject.iconName, toolObject.tooltip);
							if ('initialize' in toolObject) toolObject.initialize.call(this, gt, container);
						} else {
							const that = Object.create(new.target.prototype);
							// The initialize method is required if not deriving from another class.  It is essentially
							// the constructor in this case.
							toolObject.initialize.call(this, gt, container);
							return that;
						}
					}

					activate() {
						if (parentTool) super.activate();
						if ('activate' in toolObject) toolObject.activate.call(this, gt);
					}

					deactivate() {
						if ('deactivate' in toolObject) toolObject.deactivate.call(this, gt);
						if (parentTool) super.deactivate();
					}

					updateHighlights(coords) {
						if ('updateHighlights' in toolObject) return toolObject.updateHighlights.call(this, gt, coords);
						if (parentTool) super.updateHighlights();
					}

					removeHighlights() {
						if ('removeHighlights' in toolObject) toolObject.removeHighlights.call(this, gt);
						if (parentTool) super.removeHighlights();
					}
				}

				if ('helperMethods' in toolObject) {
					Object.keys(toolObject.helperMethods).forEach((method) => {
						customTool[method] = function(...args) {
							return toolObject.helperMethods[method].apply(this, [gt, ...args]);
						};
					});
				}

				gt.toolTypes[tool] = customTool;
			});
		}

		availableTools.forEach((tool) => {
			if (tool in gt.toolTypes) new gt.toolTypes[tool](buttonBox);
			else console.log('Unknown tool: ' + tool);
		});

		const confirmDialog = (title, titleId, message, yesAction) => {
			const modal = document.createElement('div');
			modal.classList.add('modal', 'modal-dialog-centered', 'gt-modal');
			modal.tabIndex = -1;
			modal.setAttribute('aria-labelledby', titleId);
			modal.setAttribute('aria-hidden', 'true');

			const modalDialog = document.createElement('div');
			modalDialog.classList.add('modal-dialog');
			const modalContent = document.createElement('div');
			modalContent.classList.add('modal-content');

			const modalHeader = document.createElement('div');
			modalHeader.classList.add('modal-header');

			const titleH3 = document.createElement('h3');
			titleH3.id = titleId;
			titleH3.textContent = title;

			const closeButton = document.createElement('button');
			closeButton.type = 'button';
			closeButton.classList.add('btn-close');
			closeButton.dataset.bsDismiss = 'modal';
			closeButton.setAttribute('aria-label', 'close');

			modalHeader.append(titleH3, closeButton);

			const modalBody = document.createElement('div');
			modalBody.classList.add('modal-body');
			const modalBodyContent = document.createElement('div');
			modalBodyContent.textContent = message;
			modalBody.append(modalBodyContent);

			const modalFooter = document.createElement('div');
			modalFooter.classList.add('modal-footer');

			const yesButton = document.createElement('button');
			yesButton.classList.add('btn', 'btn-primary');
			yesButton.textContent = 'Yes';
			yesButton.addEventListener('click', () => { yesAction(); bsModal.hide(); });

			const noButton = document.createElement('button');
			noButton.classList.add('btn', 'btn-primary');
			noButton.dataset.bsDismiss = 'modal';
			noButton.textContent = 'No';

			modalFooter.append(yesButton, noButton);
			modalContent.append(modalHeader, modalBody, modalFooter);
			modalDialog.append(modalContent);
			modal.append(modalDialog);

			const bsModal = new bootstrap.Modal(modal);
			bsModal.show();
			document.querySelector('.modal-backdrop').style.opacity = '0.2';
			modal.addEventListener('hidden.bs.modal', () => { bsModal.dispose(); modal.remove(); });
		}

		// Add a button to delete the selected object.
		const deleteButton = document.createElement('button');
		deleteButton.type = 'button';
		deleteButton.classList.add('btn', 'btn-light', 'gt-button');
		deleteButton.dataset.bsToggle = 'tooltip';
		deleteButton.title = 'Delete Selected Object';
		deleteButton.textContent = 'Delete';
		deleteButton.addEventListener('click', () => {
			deleteButton.blur();
			if (!gt.selectedObj) return;

			confirmDialog('Delete Selected Object', 'deleteObjectDialog',
				'Do you want to delete the selected object?',
				() => {
					const i = gt.graphedObjs.findIndex((obj) => obj.id() === gt.selectedObj.id());
					gt.graphedObjs[i].remove();
					gt.graphedObjs.splice(i, 1);

					gt.selectedObj = null;
					gt.updateObjects();
					gt.updateText();
				}
			);
		});
		buttonBox.append(deleteButton);

		// Add a button to remove all graphed objects.
		const clearButton = document.createElement('button');
		clearButton.type = 'button';
		clearButton.classList.add('btn', 'btn-light', 'gt-button');
		clearButton.dataset.bsToggle = 'tooltip';
		clearButton.title = 'Clear All Objects From Graph';
		clearButton.textContent = 'Clear';
		clearButton.addEventListener('click', () => {
			clearButton.blur();
			if (gt.graphedObjs.length == 0) return;

			confirmDialog('Clear Graph', 'clearGraphDialog',
				'Do you want to remove all graphed objects?',
				() => {
					gt.graphedObjs.forEach((obj) => obj.remove());
					gt.graphedObjs = [];
					gt.selectedObj = null;
					gt.selectTool.activate();
					gt.html_input.value = '';
				}
			);
		});
		buttonBox.append(clearButton);

		graphContainer.append(buttonBox);

		document.querySelectorAll('.gt-button-div[data-bs-toggle="tooltip"],.gt-button[data-bs-toggle="tooltip"]')
			.forEach((tooltip) => new bootstrap.Tooltip(tooltip,
				{ placement: 'bottom', trigger: 'hover', delay: { show: 500, hide: 0 } }));
	}

	setupBoard();

	// Restore data from previous attempts if available
	const restoreObjects = (data, objectsAreStatic) => {
		gt.board.suspendUpdate();
		const tmpIsStatic = gt.isStatic;
		gt.isStatic = objectsAreStatic;
		const objectRegexp = /{(.*?)}/g;
		let objectData = objectRegexp.exec(data);
		while (objectData) {
			const obj = GraphObject.restore(objectData[1]);
			if (obj !== false) {
				if (objectsAreStatic) gt.staticObjs.push(obj);
				else gt.graphedObjs.push(obj);
			}
			objectData = objectRegexp.exec(data);
		}
		gt.isStatic = tmpIsStatic;
		gt.updateObjects();
		gt.board.unsuspendUpdate();
	};

	if ('html_input' in gt) restoreObjects(gt.html_input.value, false);
	if ('staticObjects' in options && typeof(options.staticObjects) === 'string' && options.staticObjects.length)
		restoreObjects(options.staticObjects, true);
	if (!gt.isStatic) {
		gt.updateText();
		gt.activeTool = gt.selectTool;
		gt.activeTool.activate(true);
	}
};
