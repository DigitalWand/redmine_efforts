
module EffortsHelper
    def estimate_time_in_part(issue)
        internal = issue.estimated_internal
        testing = issue.estimated_testing
        control = issue.estimated_control
        "#{internal.round(2)} + #{testing.round(2)} + #{control.round(2)} = <strong>#{(internal+testing+control).round(2)}ч</strong>".html_safe
    end
end
