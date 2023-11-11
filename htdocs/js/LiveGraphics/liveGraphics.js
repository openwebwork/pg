'use strict';

(() => {
	const liveGraphics3D = (container) => {
		const options = JSON.parse(container.dataset.options);

		const width = options.width || 200;
		const height = options.height || 200;

		const maxTicks = options.maxTicks instanceof Array ? options.maxTicks : Array(3).fill(options.maxTicks ?? 6);
		while (maxTicks.length < 3) maxTicks.push(6);

		const screenReaderOnly = document.createElement('span');
		screenReaderOnly.classList.add('visually-hidden');
		screenReaderOnly.textContent = 'A manipulable 3d graph.';
		container.append(screenReaderOnly);

		// General options that can be overriden by settings in the input data.
		let lighting = true;
		let showAxes = false;
		let axesLabels = ['x', 'y', 'z'];

		// Inital view point and up vector.
		const eye = { x: 1.25, y: 1.25, z: 1.25 };
		const up = { x: 0, y: 0, z: 1 };

		// Initial graphics state. This is pushed onto the state stack when a block at depth 0 is executed. At each
		// successive block depth this state is copied and pushed onto the state stack.  The options in the state apply
		// to all graphics primitives in that block.  The state can be changed within a block by the RGBColor,
		// Thickness, and GrayLevel commands. All graphics primitives in the block after the change are affected. Also
		// note that if these are called inside an EdgeForm command, then the edge options are changed instead.
		const initialState = {
			color: null,
			lineThickness: null,
			edgeColor: 'black',
			edgeThickness: 0.001,
			pointSize: 0.01,
			edgeForm: false,
			drawEdges: true
		};
		const state = [];

		// The block index is used to group parts of surfaces, lines, and edges in the same block.
		let blockIndex = 0;

		// Data from input (translated into plotly traces).
		const surfaces = {};
		const edges = {};
		const lines = {};
		const points = [];
		const labels = [];

		let variables = '';

		const executeCommand = (command) => {
			const currentState = state.slice(-1)[0];

			if (command.id === 'Point') {
				if (command.blocks.length !== 1 || command.blocks[0].length < 3) {
					console.log('Error parsing point: A point must have three coordinates.');
					return;
				}

				// Points are implemented as the top and bottom half of a sphere.  Note that using a marker in a
				// scatter3d trace results in bad clipping since markers are really only two dimensional circles.
				const point = { type: 'mesh3d', x: [], y: [], z: [], color: 'black', hoverinfo: 'none' };

				const x = command.blocks[0][0],
					y = command.blocks[0][1],
					z = command.blocks[0][2];

				const r = currentState.pointSize * 2.5;

				point.color = `rgb(${currentState.color[0] * 255},${currentState.color[1] * 255},${
					currentState.color[2] * 255
				})`;

				const samples = 20;

				const phiValues = Array(samples)
					.fill(0)
					.map((_v, i) => (i * (Math.PI / 2)) / (samples - 1));

				const thetaValues = Array(samples)
					.fill(0)
					.map((_v, i) => (2 * i * Math.PI) / (samples - 1));

				for (const phi of phiValues) {
					for (const theta of thetaValues) {
						point.x.push(x + r * Math.cos(theta) * Math.sin(phi));
						point.y.push(y + r * Math.sin(theta) * Math.sin(phi));
						point.z.push(z + r * Math.cos(phi));
					}
				}

				// The lower hemisphere is obtained by duplicating the upper hemisphere and negating its z
				// coordinate relative to the z position of the center.
				points.push(point, { ...point, z: point.z.map((v) => 2 * z - v) });
			} else if (command.id === 'Polygon') {
				if (command.blocks.length !== 1 || command.blocks[0].length < 3) {
					console.log('Error parsing polygon: Polygons must have at least three points.');
					return;
				}

				if (!surfaces[blockIndex]) {
					surfaces[blockIndex] = {
						type: 'mesh3d',
						x: [],
						y: [],
						z: [],
						i: [],
						j: [],
						k: [],
						showscale: false,
						hoverinfo: 'none'
					};

					if (!lighting) {
						// Set the ambient lighting to the max, and disable all others.  Ambient lighting is needed
						// unless you just want a black blob for the surface.
						surfaces[blockIndex].lighting = {
							ambient: 1,
							diffuse: 0,
							fresnel: 0,
							roughness: 0,
							specular: 0
						};
					}

					if (currentState.color instanceof Array) {
						surfaces[blockIndex].color = `rgb(${currentState.color[0] * 255},${
							currentState.color[1] * 255
						},${currentState.color[2] * 255})`;
					} else {
						surfaces[blockIndex].intensity = surfaces[blockIndex].z;
						surfaces[blockIndex].colorscale = 'RdBu';
					}
				}

				if (currentState.drawEdges && !edges[blockIndex]) {
					edges[blockIndex] = {
						type: 'scatter3d',
						mode: 'lines',
						x: [],
						y: [],
						z: [],
						line: { width: currentState.edgeThickness * 1000, color: 'black' },
						hoverinfo: 'none'
					};

					if (currentState.edgeColor instanceof Array) {
						edges[blockIndex].line.color = `rgb(${currentState.edgeColor[0] * 255},${
							currentState.edgeColor[1] * 255
						},${currentState.edgeColor[2] * 255})`;
					}
				}

				const polygonIndices = [];

				for (const point of command.blocks[0]) {
					if (point.length !== 3) {
						console.log('Error parsing polygon: Points must have three coordinates.');
						return;
					}

					for (let i = 0; i < point.length; ++i) {
						try {
							point[i] = new Function(`'use strict'; { ${variables} return ${point[i]} }`)();
						} catch (e) {
							console.log(`Failed to evaluate variable quantity in coordinate of point: ${point[i]}`);
							return;
						}
					}

					// Find the index of the point in the surface x, y, z coordinate arrays.
					// If the point is not in the arrays, then add it.
					let pointIndex = 0;
					for (; pointIndex < surfaces[blockIndex].x.length; ++pointIndex) {
						if (
							surfaces[blockIndex].x[pointIndex] === point[0] &&
							surfaces[blockIndex].y[pointIndex] === point[1] &&
							surfaces[blockIndex].z[pointIndex] === point[2]
						)
							break;
					}

					if (pointIndex === surfaces[blockIndex].x.length) {
						surfaces[blockIndex].x.push(point[0]);
						surfaces[blockIndex].y.push(point[1]);
						surfaces[blockIndex].z.push(point[2]);
					}

					edges[blockIndex]?.x.push(point[0]);
					edges[blockIndex]?.y.push(point[1]);
					edges[blockIndex]?.z.push(point[2]);

					polygonIndices.push(pointIndex);
				}

				// Split the polygon into triangle faces, and add the indices of the vertices of these
				// triangles to the face index arrays.
				for (let i = 1; i < polygonIndices.length - 1; ++i) {
					surfaces[blockIndex].i.push(polygonIndices[0]);
					surfaces[blockIndex].j.push(polygonIndices[i]);
					surfaces[blockIndex].k.push(polygonIndices[i + 1]);
				}

				edges[blockIndex]?.x.push('None');
				edges[blockIndex]?.y.push('None');
				edges[blockIndex]?.z.push('None');
			} else if (command.id === 'Line') {
				if (command.blocks.length !== 1 || command.blocks[0].length < 2) {
					console.log('Error parsing line: Lines must have at least two points.');
					return;
				}

				const x = [],
					y = [],
					z = [];

				for (const point of command.blocks[0]) {
					if (point.length !== 3) {
						console.log('Error parsing line: Points must have three coordinates.');
						return;
					}

					for (let i = 0; i < point.length; ++i) {
						try {
							point[i] = new Function(`'use strict'; { ${variables} return ${point[i]} }`)();
						} catch (e) {
							console.log(`Failed to evaluate variable quantity in coordinate of point: ${point[i]}`);
							return;
						}
					}

					x.push(point[0]);
					y.push(point[1]);
					z.push(point[2]);
				}

				x.push('None');
				y.push('None');
				z.push('None');

				if (lines[blockIndex]) {
					lines[blockIndex].x.push(...x);
					lines[blockIndex].y.push(...y);
					lines[blockIndex].z.push(...z);
				} else {
					lines[blockIndex] = {
						type: 'scatter3d',
						mode: 'lines',
						x,
						y,
						z,
						line: { width: 5 },
						hoverinfo: 'none'
					};
				}

				if (currentState.color instanceof Array) {
					lines[blockIndex].line.color = `rgb(${currentState.color[0] * 255},${currentState.color[1] * 255},${
						currentState.color[2] * 255
					})`;
				}

				if (currentState.lineThickness !== null)
					lines[blockIndex].line.width = Math.max(currentState.lineThickness, 0.005) * 400;
			} else if (command.id === 'EdgeForm') {
				if (!command.blocks.length) currentState.drawEdges = false;
				else currentState.drawEdges = true;

				currentState.edgeForm = true;
				executeBlocks(command.blocks);
				currentState.edgeForm = false;
			} else if (command.id === 'RGBColor') {
				if (command.blocks.length === 3) {
					if (currentState.edgeForm) currentState.edgeColor = command.blocks;
					else currentState.color = command.blocks;
				}
			} else if (command.id === 'GrayLevel') {
				if (command.blocks.length === 1) {
					if (currentState.edgeForm)
						currentState.edgeColor = [command.blocks[0], command.blocks[0], command.blocks[0]];
					else currentState.color = [command.blocks[0], command.blocks[0], command.blocks[0]];
				}
			} else if (command.id === 'Thickness') {
				if (command.blocks.length === 1) {
					if (currentState.edgeForm) currentState.edgeThickness = command.blocks[0];
					else currentState.lineThickness = command.blocks[0];
				}
			} else if (command.id === 'PointSize') {
				if (command.blocks.length === 1) currentState.pointSize = command.blocks[0];
			} else if (command.id === 'Text') {
				if (command.blocks.length < 2 || command.blocks[1].length !== 3) {
					console.log('Error parsing label: Missing arguments.');
					return;
				}

				const label = {
					type: 'scatter3d',
					mode: 'text',
					textfont: { color: 'black', size: 12, family: 'mono' },
					textposition: 'top center',
					hoverinfo: 'none'
				};

				label.x = [command.blocks[1][0]];
				label.y = [command.blocks[1][1]];
				label.z = [command.blocks[1][2]];

				if (command.blocks[0].id !== 'StyleForm' || command.blocks[0].blocks.length !== 1) {
					console.log('Error parsing label: No text provided.');
					return;
				}

				label.text = command.blocks[0].blocks[0];
				if (command.blocks[0].attributes.FontSize) label.textfont.size = command.blocks[0].attributes.FontSize;

				labels.push(label);
			}
		};

		const executeBlocks = (blocks) => {
			if (!state.slice(-1)[0]?.edgeForm) {
				if (state.length) state.push(Object.assign({}, state.slice(-1)[0]));
				else state.push(initialState);
				++blockIndex;
			}

			for (const block of blocks) {
				if (block instanceof Array) {
					for (const subBlock of block) {
						if (subBlock instanceof Array) executeBlocks(subBlock);
						else executeCommand(subBlock);
					}
				} else executeCommand(block);
			}

			if (!state.slice(-1)[0].edgeForm) state.pop();
		};

		const parseLive3DData = (data) => {
			// Set up variables.
			for (const [name, data] of Object.entries(options.vars)) {
				variables += `const ${name} = ${data};`;
			}

			if (data.attributes.Axes === true) showAxes = true;

			if (data.attributes.AxesLabel instanceof Array && data.attributes.AxesLabel.length === 3)
				axesLabels = data.attributes.AxesLabel;

			if (data.attributes.ViewPoint instanceof Array && data.attributes.ViewPoint.length === 3) {
				eye.x = data.attributes.ViewPoint[0];
				eye.y = data.attributes.ViewPoint[1];
				eye.z = data.attributes.ViewPoint[2];
			}

			if (data.attributes.ViewVertical instanceof Array && data.attributes.ViewVertical.length === 3) {
				up.x = data.attributes.ViewVertical[0];
				up.y = data.attributes.ViewVertical[1];
				up.z = data.attributes.ViewVertical[2];
			}

			if ('Lighting' in data.attributes) lighting = data.attributes.Lighting;

			executeBlocks(data.blocks);
		};

		const parseArray = (stream, parent, delim = '[') => {
			let delimCount = 1;
			let block = [];

			const oppDelim = delim === '[' ? ']' : delim === '{' ? '}' : '\n';

			while (stream.length && stream[0] !== delim) stream.shift();
			stream.shift();

			while (stream.length) {
				if (stream[0].match(/^\s/)) {
					stream.shift();
					continue;
				}

				const char = stream.shift();

				if (char === oppDelim) {
					--delimCount;
					if (delimCount == 0) break;
				}

				block.push(char);

				if (char === delim) ++delimCount;
			}

			const array = [];

			while (block.length) {
				const element = extractNext(block, parent);
				if (typeof element !== 'undefined') array.push(element);
				if (block.length && block[0] === ',') block.shift();
			}

			return array;
		};

		const extractNext = (stream, parent = {}) => {
			if (!stream.length) return;

			// Block
			if (stream[0] === '{') return parseArray(stream, parent, '{');

			let identifier = '';
			while (stream.length && stream[0].match(/^[A-Za-z]/)) identifier += stream.shift();

			if (identifier) {
				while (stream.length && stream[0].match(/^[A-Za-z0-9]/)) identifier += stream.shift();

				// Attribute
				if (stream.length && stream[0] === '-' && stream[1] === '>') {
					stream.shift();
					stream.shift();
					const value = extractNext(stream, parent);
					if (!parent.attributes) parent.attributes = {};
					parent.attributes[identifier] = value;
					return;
				}

				// Command
				if (stream.length && stream[0] === '[') {
					const command = { id: identifier };
					command.blocks = parseArray(stream, command);
					return command;
				}
			}

			// The last case is that of a scalar argument for a command or attribute.  So accumulate everything
			// up to the next comma or the end of the stream if that comes first.
			while (stream.length && stream[0] !== ',') identifier += stream.shift();

			if (identifier.toLowerCase() === 'true') return true;
			if (identifier.toLowerCase() === 'false') return false;

			if (/^[+-]?\d+\.?\d*$/.test(identifier)) return parseFloat(identifier);

			return identifier;
		};

		const parseLive3DString = (text) => {
			const stream = text.replaceAll(/\s*/g, '').split('');
			return extractNext(stream);
		};

		// Parse the data string and translate it into plotly traces.
		const initialize = (datastring) => {
			try {
				// Parse LiveGraphics3D string into a javascript object.
				const data = parseLive3DString(datastring);
				if (!data || data.id !== 'Graphics3D') throw 'Unable to parse live graphics 3d data string.';
				// Evaluate data.
				parseLive3DData(data);
			} catch (e) {
				console.log(e);
				return;
			}

			Plotly.newPlot(
				container,
				[...Object.values(surfaces), ...Object.values(edges), ...Object.values(lines), ...points, ...labels],
				{
					width,
					height,
					margin: { l: 5, r: 5, b: 5, t: 5 },
					showlegend: false,
					paper_bgcolor: 'white',
					scene: {
						xaxis: {
							visible: showAxes,
							title: axesLabels[0],
							nticks: maxTicks[0],
							showspikes: false
						},
						yaxis: {
							visible: showAxes,
							title: axesLabels[1],
							nticks: maxTicks[1],
							showspikes: false
						},
						zaxis: {
							visible: showAxes,
							title: axesLabels[2],
							nticks: maxTicks[2],
							showspikes: false
						},
						camera: { eye, up }
					}
				},
				{ displaylogo: false }
			);
		};

		// This section of code is run whenever the object is created.  It obtains the data either from direct input, a
		// zip file, or a data file.  Then it calls intialize with the data string.

		if (options.input) {
			initialize(options.input);
		} else if (options.archive) {
			// If an archive file is provided then retrieve that file.
			// The file name is the file inside the archive that contains the data.
			JSZipUtils.getBinaryContent(options.archive, (error, data) => {
				if (error) {
					console.log(error);
					container.innerHTML = 'Failed to get input archive';
				}

				JSZip.loadAsync(data).then((zip) => {
					zip.file(options.file)
						.async('string')
						.then((string) => initialize(string));
				});
			});
		} else if (options.file) {
			fetch(options.file)
				.then((response) => (response.ok ? response.text() : response))
				.then((data) => initialize(data))
				.catch((error) => {
					console.log(error);
					container.innerHTML = 'Failed to get input file';
				});
		} else {
			container.innerHTML = 'No input data provided';
		}
	};

	// Deal with live graphics 3d elements that are already on the page.
	document.querySelectorAll('.live-graphics-3d-container').forEach(liveGraphics3D);

	// Deal with live graphics 3d elements that are added to the page later.
	const observer = new MutationObserver((mutationsList) => {
		mutationsList.forEach((mutation) => {
			mutation.addedNodes.forEach((node) => {
				if (node instanceof Element) {
					if (node.classList.contains('live-graphics-3d-container')) liveGraphics3D(node);
					else node.querySelectorAll('.live-graphics-3d-container').forEach(liveGraphics3D);
				}
			});
		});
	});
	observer.observe(document.body, { childList: true, subtree: true });
})();
