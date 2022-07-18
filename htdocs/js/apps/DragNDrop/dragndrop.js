(function() {
	class DragNDropBucket {
		constructor(pgData) {
			this.answerInputId = pgData['answerInputId'];
			this.bucketId = pgData['bucketId'];
			this.label = pgData['label'] || '';
			this.removable = pgData['removable'];
			this.bucketPool = $('.dd-bucket-pool[data-ans="' + this.answerInputId + '"]').first()[0];

			const $bucketPool = $(this.bucketPool);
			const $newBucket = this._newBucket(
				this.bucketId,
				this.label,
				this.removable,
				$bucketPool.find('.dd-hidden.dd-past-answers.dd-bucket[data-bucket-id="' + this.bucketId + '"]')
			);

			$bucketPool.append($newBucket);

			const el = this;

			$newBucket.find('.dd').nestable({
				group: el.answerInputId,
				maxDepth: 1,
				scroll: true,
				callback: function() {el._nestableUpdate();}
			});
			this._nestableUpdate();
			this._ddUpdate();
		}

		_newBucket(bucketId, label, removable, $bucketHtmlElement) {
			const $newBucket = $('<div id="nestable-' + bucketId + '-container" class="dd-container"></div>');

			$newBucket.attr('data-bucket-id', bucketId);
			$newBucket.append($('<div class="nestable-label">' + label + '</div>'));
			$newBucket.append($('<div class="dd" data-bucket-id="' + bucketId + '"></div>'));

			if (removable != 0) {
				$newBucket.append($('<button type="button" class="btn btn-secondary dd-remove-bucket">Remove</button>'));
			}

			if ($bucketHtmlElement.find('ol.dd-answer li').length) {
				const $ddList = $('<ol class="dd-list"></ol>');

				$bucketHtmlElement.find('ol.dd-answer li').each(function() {
					const $item = $('<li><div class="dd-handle">' + $(this).html() + '</div></li>');

					$item.addClass('dd-item').attr('data-shuffled-index', $(this).attr('data-shuffled-index'));
					$ddList.append($item);
				});
				$newBucket.find('.dd').first().append($ddList);
			}
			$newBucket.css('background-color', 'hsla(' + ((100 + (bucketId)*100) % 360) + ', 40%, 90%, 1)');
			return $newBucket;
		}

		_nestableUpdate() {
			const buckets = [];

			$(this.bucketPool).find('.dd').each(function() {
				const list = [];

				$(this).find('li.dd-item').each(function() {
					list.push($(this).attr('data-shuffled-index'));
				});
				if (list.length) {
					buckets.push('(' + list.join(",") + ')');
				} else {
					buckets.push('(-1)');
				}
			});

			$("#" +  this.answerInputId).val(buckets.join(","));
		}

		_ddUpdate() {
			const answerInputId = this.answerInputId;
			const $bucketPool = $('.dd-bucket-pool[data-ans="' + answerInputId + '"]').first();
			const el = this;

			$(function() {
				$bucketPool.parent().find('.dd-add-bucket').off();
				$bucketPool.parent().find('.dd-add-bucket').on('click', function() {
					new DragNDropBucket({
						answerInputId: $(this).attr('data-ans'),
						bucketId: +($('.dd').length) + 1,
						removable: 1,
						label:'',
					});
				});
				$bucketPool.find('.dd-remove-bucket').off();
				$bucketPool.find('.dd-remove-bucket').on('click', function() {
					if ($bucketPool.find('.dd ol').length == 1) {
						return 0;
					}
					const $container = $(this).closest('.dd-container');

					$container.find('li').appendTo($bucketPool.find('.dd ol').first());
					$container.remove();
					el._nestableUpdate();
				});
				$bucketPool.parent().find('.dd-reset-buckets').off();
				$bucketPool.parent().find('.dd-reset-buckets').on('click', function() {
					$bucketPool.find('.dd-container').remove();
					$bucketPool.find('div.dd-hidden.dd-default.dd-bucket').each(function() {
						const bucketId = $(this).attr('data-bucket-id');
						const $bucket = el._newBucket(
							$(this).attr('data-bucket-id'),
							$(this).find('.dd-label').first().html(),
							$(this).attr('data-removable'),
							$bucketPool.find('.dd-hidden.dd-default.dd-bucket[data-bucket-id="' + bucketId + '"]')
						);

						$bucketPool.append($bucket);
					});

					$bucketPool.find('.dd').nestable({
						group: el.answerInputId,
						maxDepth: 1,
						scroll: true,
						callback: function() {el._nestableUpdate();}
					});
					el._nestableUpdate();
				});
			});
		}

	}

	$('div.dd-bucket-pool').each(function() {
		const answerInputId = $(this).attr('data-ans');

		if ($(this).find('div.dd-bucket.dd-past-answers.dd-hidden').length) {
			$(this).find('div.dd-bucket.dd-past-answers.dd-hidden').each(function() {
				new DragNDropBucket({
					answerInputId : answerInputId,
					bucketId : $(this).attr('data-bucket-id'),
					label : $(this).find('.dd-label').html(),
					removable : $(this).attr('data-removable'),
				});
			});
		}
	});

})();
