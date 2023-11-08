'use strict';

(() => {
	const liveGraphics3D = (container) => {
		const options = JSON.parse(container.dataset.options);

		// Set default options.
		options.width = options.width ?? 200;
		options.height = options.height ?? 200;
		options.showAxes = options.showAxes ?? false;
		options.showAxesCube = options.showAxesCube ?? true;
		options.numTicks = options.numTicks ?? 4;
		options.axisKey = options.axisKey ?? ['x', 'y', 'z'];
		options.drawMesh = options.drawMesh ?? true;

		const screenReaderOnly = document.createElement('span');
		screenReaderOnly.classList.add('visually-hidden');
		screenReaderOnly.textContent = 'A manipulable 3d graph.';
		container.append(screenReaderOnly);

		// Inital view point and up vector.
		const eye = { x: 1.25, y: 1.25, z: 1.25 };
		const up = { x: 0, y: 0, z: 1 };

		// Colors and thicknesses drawn from input.
		const colors = {};
		const lineThickness = {};

		// Block indexes are used to associate objects to colors and thicknesses.
		let blockIndex = 0;

		// Data from input (translated into plotly traces).
		const surfaces = {};
		const lines = {};
		const points = [];
		const labels = [];

		let variables = '';

		// Split a list of mathematica commands into blocks.
		const splitMathematicaBlocks = (text) => {
			let bracketcount = 0;
			const blocks = [];
			let block = '';

			for (let i = 0; i < text.length; ++i) {
				block += text.charAt(i);

				if (text.charAt(i) === '[') ++bracketcount;

				if (text.charAt(i) === ']') {
					--bracketcount;
					if (bracketcount == 0) {
						++i;
						blocks.push(block);
						block = '';
					}
				}
			}

			return blocks;
		};

		// The mathematica code comes in blocks enclosed by braces.  This code makes an array from those blocks.
		// The largest of them will be the polygon block which defines the surface.
		const recurseMathematicaBlocks = (text, initialcount) => {
			let bracketcount = 0;
			const blocks = [];
			let block = '';

			if (initialcount) bracketcount = initialcount;

			for (let i = 0; i < text.length; ++i) {
				if (text.charAt(i) === '{') ++bracketcount;

				if (bracketcount > 0) block += text.charAt(i);

				if (text.charAt(i) === '}') {
					--bracketcount;
					if (bracketcount == 0) {
						blocks.push(block.substring(1, block.length - 1));
						block = '';
					}
				}
			}

			return blocks;
		};

		const parseMathematicaBlocks = (blocks) => {
			for (const block of blocks) {
				++blockIndex;

				if (block.match(/^\s*\{/)) {
					// This is a block inside of a block.  So recurse.
					parseMathematicaBlocks(recurseMathematicaBlocks(block));
				} else if (block.match(/Point/)) {
					// Points are defined by short blocks so don't split into individual commands.
					let pointStr = block.match(
						/Point\[\s*\{\s*(-?\d*\.?\d*)\s*,\s*(-?\d*\.?\d*)\s*,\s*(-?\d*\.?\d*)\s*\}/
					);
					if (!pointStr || pointStr.length < 4) {
						console.log('Error Parsing Point');
						continue;
					}

					// Points are implemented as the top and bottom half of a sphere.  Note that using a marker in a
					// scatter3d trace results in bad clipping since markers are really only two dimensional circles.
					const point = { type: 'mesh3d', x: [], y: [], z: [], color: 'black', hoverinfo: 'none' };

					const x = parseFloat(pointStr[1]),
						y = parseFloat(pointStr[2]),
						z = parseFloat(pointStr[3]);

					const pointSizeStr = block.match(/PointSize\[\s*(\d*\.?\d*)\s*\]/);
					const r = pointSizeStr && pointSizeStr.length == 2 ? parseFloat(pointSizeStr[1]) * 2.5 : 0.025;

					const colorStr = block.match(/RGBColor\[\s*(\d*\.?\d*)\s*,\s*(\d*\.?\d*)\s*,\s*(\d*\.?\d*)\s*\]/);
					if (colorStr) point.color = `rgb(${colorStr[1] * 255},${colorStr[2] * 255},${colorStr[3] * 255})`;

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
				} else {
					// Otherwise its a list of commands that need to be individually processed.
					for (const command of splitMathematicaBlocks(block)) {
						if (command.match(/^\s*\{/)) {
							// This is a block inside of a block.  So recurse.
							parseMathematicaBlocks(recurseMathematicaBlocks(block));
						} else if (command.match(/Polygon/)) {
							// Extract all points of the polygon.
							const polygonPoints = [];
							try {
								const pointStrings = recurseMathematicaBlocks(
									command.replace(/Polygon\[([^\]]*)\]/, '$1'),
									-1
								);
								if (pointStrings.length < 3) throw 'Polygons must have at least thre points.';

								for (const pointString of pointStrings) {
									const coordStrings = pointString.replace(/\{([^\{]*)\}/, '$1').split(',');
									if (coordStrings.length !== 3) throw 'Points must have three coordinates.';

									const point = [];

									for (const coordString of coordStrings) {
										point.push(
											parseFloat(
												new Function(`'use strict'; { ${variables} return ${coordString} }`)()
											)
										);
									}

									polygonPoints.push(point);
								}
							} catch (e) {
								console.log(`Error parsing polygon: ${e}`);
								continue;
							}
							if (!surfaces[blockIndex]) {
								surfaces[blockIndex] = {
									surface: {
										type: 'mesh3d',
										x: [],
										y: [],
										z: [],
										i: [],
										j: [],
										k: [],
										showscale: false,
										hoverinfo: 'none'
									},
									mesh: {
										type: 'scatter3d',
										mode: 'lines',
										x: [],
										y: [],
										z: [],
										line: { width: 1, color: 'black' },
										hoverinfo: 'none'
									}
								};
							}

							const polygonIndices = [];

							for (const point of polygonPoints) {
								// Find the index of the point in the surface x, y, z coordinate arrays.
								// If the point is not in the arrays, then add it.
								let pointIndex = 0;
								for (; pointIndex < surfaces[blockIndex].surface.x.length; ++pointIndex) {
									if (
										surfaces[blockIndex].surface.x[pointIndex] === point[0] &&
										surfaces[blockIndex].surface.y[pointIndex] === point[1] &&
										surfaces[blockIndex].surface.z[pointIndex] === point[2]
									)
										break;
								}

								if (pointIndex === surfaces[blockIndex].surface.x.length) {
									surfaces[blockIndex].surface.x.push(point[0]);
									surfaces[blockIndex].surface.y.push(point[1]);
									surfaces[blockIndex].surface.z.push(point[2]);
								}

								surfaces[blockIndex].mesh.x.push(point[0]);
								surfaces[blockIndex].mesh.y.push(point[1]);
								surfaces[blockIndex].mesh.z.push(point[2]);

								polygonIndices.push(pointIndex);
							}

							// Split the polygon into triangle faces, and add the indices of the vertices of these
							// triangles to the face index arrays.
							for (let i = 1; i < polygonIndices.length - 1; ++i) {
								surfaces[blockIndex].surface.i.push(polygonIndices[0]);
								surfaces[blockIndex].surface.j.push(polygonIndices[i]);
								surfaces[blockIndex].surface.k.push(polygonIndices[i + 1]);
							}

							surfaces[blockIndex].mesh.x.push('None');
							surfaces[blockIndex].mesh.y.push('None');
							surfaces[blockIndex].mesh.z.push('None');
						} else if (command.match(/Line/)) {
							const x = [],
								y = [],
								z = [];

							try {
								const pointStrings = recurseMathematicaBlocks(
									command.replace(/Line\[([^\]]*)\],/, '$1'),
									-1
								);
								if (pointStrings.length < 2) throw 'Lines must have at least two points.';

								for (const pointString of pointStrings) {
									const coordStrings = pointString.split(',');
									if (coordStrings.length !== 3) throw 'Points must have three coordinates.';

									const point = [];

									for (const coordString of coordStrings) {
										point.push(
											parseFloat(
												new Function(`'use strict'; { ${variables} return ${coordString} }`)()
											)
										);
									}

									x.push(point[0]);
									y.push(point[1]);
									z.push(point[2]);
								}
							} catch (e) {
								console.log(`Error parsing line: ${e}`);
								continue;
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
						} else if (command.match(/RGBColor/)) {
							const str = command.match(
								/RGBColor\[\s*(\d*\.?\d*)\s*,\s*(\d*\.?\d*)\s*,\s*(\d*\.?\d*)\s*\]/
							);
							if (str && str.length === 4)
								colors[blockIndex] = [parseFloat(str[1]), parseFloat(str[2]), parseFloat(str[3])];
						} else if (command.match(/Thickness/)) {
							const str = command.match(/Thickness\[\s*(\d*\.?\d*)\s*\]/);
							if (str && str.length === 2) lineThickness[blockIndex] = parseFloat(str[1]);
						} else if (command.match(/Text/)) {
							const labelStr = command.match(
								/\{\s*(-?\d*\.?\d*)\s*,\s*(-?\d*\.?\d*)\s*,\s*(-?\d*\.?\d*)\s*\}/
							);
							if (!labelStr || labelStr.length !== 4) {
								console.log('Error Parsing Label');
								continue;
							}

							const label = {
								type: 'scatter3d',
								mode: 'text',
								textfont: { color: 'black', size: 12, family: 'mono' },
								textposition: 'top center',
								hoverinfo: 'none'
							};

							label.x = [parseFloat(labelStr[1])];
							label.y = [parseFloat(labelStr[2])];
							label.z = [parseFloat(labelStr[3])];

							const optionsStr = command.match(/StyleForm\[\s*(\w+),\s*FontSize\s*->\s*(\d+)\s*\]/);
							if (!optionsStr || optionsStr.length < 3) {
								console.log('Error parsing label.');
								continue;
							}

							label.text = [optionsStr[1]];
							label.textfont.size = optionsStr[2];

							labels.push(label);
						}
					}
				}
			}
		};

		const parseLive3DData = (text) => {
			// Set up variables.
			for (const [name, data] of Object.entries(options.vars)) {
				variables += `const ${name} = ${data};`;
			}

			// Parse axes commands.
			if (text.match(/Axes\s*->\s*True/)) options.showAxes = true;

			const labels = text.match(/AxesLabel\s*->\s*\{\s*(\w+),\s*(\w+),\s*(\w+)\s*\}/);
			if (labels && labels.length === 4) options.axisKey = [labels[1], labels[2], labels[3]];

			const viewPoint = text.match(
				/ViewPoint\s*->\s*\{\s*(-?\d*\.?\d*)\s*,\s*(-?\d*\.?\d*)\s*,\s*(-?\d*\.?\d*)\s*\}/
			);
			if (viewPoint && viewPoint.length === 4) {
				eye.x = parseFloat(viewPoint[1]);
				eye.y = parseFloat(viewPoint[2]);
				eye.z = parseFloat(viewPoint[3]);
			}

			const viewVertical = text.match(
				/ViewVertical\s*->\s*\{\s*(-?\d*\.?\d*)\s*,\s*(-?\d*\.?\d*)\s*,\s*(-?\d*\.?\d*)\s*\}/
			);
			if (viewVertical && viewVertical.length === 4) {
				up.x = parseFloat(viewVertical[1]);
				up.y = parseFloat(viewVertical[2]);
				up.z = parseFloat(viewVertical[3]);
			}

			// Split the input into blocks and parse.
			parseMathematicaBlocks(recurseMathematicaBlocks(text));
		};

		// Parse the data string and translate it into plotly traces.
		const initialize = (datastring) => {
			// Parse LiveGraphics3D string.
			parseLive3DData(datastring);

			const traces = [];

			for (const [blockIndex, surface] of Object.entries(surfaces)) {
				if (blockIndex in colors) {
					surface.surface.color = `rgb(${colors[blockIndex][0] * 255},${colors[blockIndex][1] * 255},${
						colors[blockIndex][2] * 255
					})`;
				} else {
					surface.surface.intensity = surface.surface.z;
					surface.surface.colorscale = 'RdBu';
				}

				traces.push(surface.surface);
				if (options.drawMesh) traces.push(surface.mesh);
			}

			for (const [blockIndex, line] of Object.entries(lines)) {
				if (blockIndex in colors)
					line.line.color = `rgb(${colors[blockIndex][0] * 255},${colors[blockIndex][1] * 255},${
						colors[blockIndex][2] * 255
					})`;

				if (blockIndex in lineThickness) {
					line.line.width = Math.max(lineThickness[blockIndex], 0.005) * 400;
				}

				traces.push(line);
			}

			traces.push(...points, ...labels);

			Plotly.newPlot(
				container,
				traces,
				{
					width: options.width,
					height: options.height,
					margin: { l: 5, r: 5, b: 5, t: 5 },
					showlegend: false,
					paper_bgcolor: 'white',
					scene: {
						xaxis: {
							visible: options.showAxes,
							title: options.axisKey[0],
							nticks: options.numTicks + 2,
							showspikes: false
						},
						yaxis: {
							visible: options.showAxes,
							title: options.axisKey[1],
							nticks: options.numTicks + 2,
							showspikes: false
						},
						zaxis: {
							visible: options.showAxes,
							title: options.axisKey[2],
							nticks: options.numTicks + 2,
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
