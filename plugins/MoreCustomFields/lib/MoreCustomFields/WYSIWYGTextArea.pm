package MoreCustomFields::WYSIWYGTextArea;

use strict;

use MT 4.2;
use base qw(MT::Plugin);

sub _field_html {
    return q{
<script src="<mt:Var name="static_uri">support/plugins/morecustomfields/ckeditor/ckeditor.js"></script>
<script src="<mt:Var name="static_uri">support/plugins/morecustomfields/ckeditor/adapters/jquery.js"></script>
<script>
jQuery(document).ready(function($) {
    $('textarea#<mt:Var name="field_name">').ckeditor();
});
</script>

<textarea
    name="<mt:Var name="field_name">"
    id="<mt:Var name="field_name">"
    class="text low"><mt:Var name="field_value" escape="html"></textarea>

    };
}

1;

__END__
