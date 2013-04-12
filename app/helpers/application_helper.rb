module ApplicationHelper
	def init_skrollr
		javascript_tag "
			$(function() {
				var s = skrollr.init();
			});"
	end
end
