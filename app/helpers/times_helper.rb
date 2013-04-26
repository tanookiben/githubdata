module TimesHelper
	def init_skrollr
		javascript_tag "
			$(function() {
				var s = skrollr.init();
			});"
	end
	def check_selection
		javascript_tag "
			$(function() {
				$('#languages').click(
					function() { 
						var num_selected = $('#languages').val().length;
						var $warning = $('#warning');
						var $btn = $('.btn');
						if(num_selected > 5) {
							$warning.text('You can only select a maximum of five languages');
							$btn.attr('disabled','disabled');
						} else {
							$warning.text('');
							$btn.removeAttr('disabled');
						}
					});
				});"
	end
end
