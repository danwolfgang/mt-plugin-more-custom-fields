package MoreCustomFields::Plugin;

use strict;
use warnings;

use MT 4.2;
use base qw(MT::Plugin);
use CustomFields::Util qw( get_meta save_meta field_loop _get_html );
use MT::Util qw( relative_date offset_time offset_time_list epoch2ts 
                 ts2epoch format_ts encode_html dirify );

use MoreCustomFields::CheckboxGroup;
use MoreCustomFields::RadioButtonsWithInput;
use MoreCustomFields::SelectedAssets;
use MoreCustomFields::SelectedEntriesOrPages;
use MoreCustomFields::SelectedEntries;
use MoreCustomFields::SelectedPages;
use MoreCustomFields::SelectedComments;
use MoreCustomFields::SingleLineTextGroup;
use MoreCustomFields::Message;
use MoreCustomFields::TimestampedTextarea;
use MoreCustomFields::ReciprocalObject;
use MoreCustomFields::WYSIWYGTextArea;

sub init_app {
    my $plugin = shift;
    my ($app) = @_;
    return if $app->id eq 'wizard';

    my $r = $plugin->registry;
    my $tags = _load_tags( $app, $plugin );
    # If any tags were needed, merge them into the registry.
    if ( ref($tags) eq 'HASH' ) {
        MT::__merge_hash($r->{tags}, $tags);
    }

    # If this is MT4, we need to use the `setup_terms_args` key to help make
    # the Selected Entries or Pages CF search work.
    if ($app->product_version =~ /^4/) {
        # Build the additional registry details. Note that the tree is actually
        # applications -> cms -> search_apis -> entry -> setup_terms_args
        my $reg = {
            'search_apis' => {
                'entry' => {
                    'setup_terms_args' => sub {
                        my $terms   = shift;
                        my $args    = shift;
                        my $blog_id = shift;

                        # Arguments need to be specified because using
                        # `setup_terms_args` means all of the query needs to be
                        # built here. Start with the generic values used to
                        # build any search.
                        $terms->{blog_id}  = $blog_id;
                        $args->{sort}      = 'created_on';
                        $args->{direction} = 'descend';

                        # If this isn't an MCF-initiated search, exit now.
                        # Because the basic terms and arguments were already
                        # built above, we can quit now and the search will
                        # still execute in the expected manner. But, if this
                        # *is* an MCF-initiated search then we can apply the
                        # final parameters to get the desired results.
                        return 1 unless $app->mode eq 'mcf_list_content';

                        # Search the current blog, and search both Entries and
                        # Pages for the term.
                        $terms->{class}   = '*';
                    },
                },
            },
        };

        # Merge the updated registry keys with the plugin's registry entries.
        my $plugin = MT->component('morecustomfields');
        MT::__merge_hash($plugin->registry('applications', 'cms'), $reg);
    }
}

# Build the tags associated with all of these new fields, and return them to 
# the init_app callback.
sub _load_tags {
    my $app  = shift;
    my $tags = {};

    $tags = MoreCustomFields::SingleLineTextGroup::_create_tags({
        tags => $tags,
    });
    $tags = MoreCustomFields::TimestampedTextarea::_create_tags({
        tags => $tags,
    });

    return $tags;
}


sub load_customfield_types {
    my $customfield_types = {
        checkbox_group => {
            label             => 'Checkbox Group',
            column_def        => 'vchar',
            order             => 301,
            no_default        => 1,
            options_delimiter => ',',
            options_field     => sub { MoreCustomFields::CheckboxGroup::_options_field(); },
            field_html        => sub { MoreCustomFields::CheckboxGroup::_field_html(); },
        },
        radio_input => {
            label             => 'Radio Buttons (with Input field)',
            column_def        => 'vchar',
            order             => 701,
            no_default        => 1,
            options_delimiter => ',',
            options_field     => sub { MoreCustomFields::RadioButtonsWithInput::_options_field(); },
            field_html        => sub { MoreCustomFields::RadioButtonsWithInput::_field_html(); },
            field_html_params => sub { MoreCustomFields::RadioButtonsWithInput::_field_html_params(@_); },
        },
        selected_entries => {
            label             => 'Selected Entries',
            column_def        => 'vchar',
            order             => 2100,
            no_default        => 1,
            options_delimiter => ',',
            options_field     => sub { MoreCustomFields::SelectedEntries::_options_field(); },
            field_html        => sub { MoreCustomFields::SelectedObject::_field_html(); },
            field_html_params => sub { MoreCustomFields::SelectedObject::_field_html_params(@_); },
        },
        selected_pages => {
            label             => 'Selected Pages',
            column_def        => 'vchar',
            order             => 2101,
            no_default        => 1,
            options_delimiter => ',',
            options_field     => sub { MoreCustomFields::SelectedPages::_options_field(); },
            field_html        => sub { MoreCustomFields::SelectedObject::_field_html(); },
            field_html_params => sub { MoreCustomFields::SelectedObject::_field_html_params(@_); },
        },
        selected_content => {
            label             => 'Selected Entries or Pages',
            column_def        => 'vchar',
            order             => 2102,
            no_default        => 1,
            options_delimiter => ',',
            options_field     => sub { MoreCustomFields::SelectedEntriesOrPages::_options_field(); },
            field_html        => sub { MoreCustomFields::SelectedObject::_field_html(); },
            field_html_params => sub { MoreCustomFields::SelectedObject::_field_html_params(@_); },
        },
        selected_comments => {
            label             => 'Selected Comments',
            column_def        => 'vchar',
            order             => 2103,
            no_default        => 1,
            options_delimiter => ',',
            options_field     => sub {
                MoreCustomFields::SelectedObject::options_field({
                    type => 'comments',
                });
            },
            field_html        => sub { MoreCustomFields::SelectedComments::_field_html(); },
            field_html_params => sub { MoreCustomFields::SelectedComments::_field_html_params(@_); },
        },
#        single_line_text_group => {
#            label             => 'Single-Line Text Group',
#            column_def        => 'vblob',
#            order             => 101,
#            no_default        => 1,
#            options_delimiter => ',',
#            options_field     => sub { MoreCustomFields::SingleLineTextGroup::_options_field(); },
#            field_html        => sub { MoreCustomFields::SingleLineTextGroup::_field_html(); },
#            field_html_params => sub { MoreCustomFields::SingleLineTextGroup::_field_html_params(@_); },
#        },
        multi_use_single_line_text_group => {
            label             => 'Multi-Use Single-Line Text Group',
            column_def        => 'vblob',
            order             => 102,
            no_default        => 1,
            options_delimiter => ',',
            options_field     => sub { MoreCustomFields::SingleLineTextGroup::_options_field(); },
            field_html        => sub { MoreCustomFields::SingleLineTextGroup::_multi_field_html(); },
            field_html_params => sub { MoreCustomFields::SingleLineTextGroup::_multi_field_html_params(@_); },
        },
        multi_use_timestamped_multi_line_text => {
            label             => 'Multi-Use Time Stamped Multi-Line Text',
            column_def        => 'vblob',
            order             => 202,
            no_default        => 1,
            field_html        => sub { MoreCustomFields::TimestampedTextarea::_field_html(); },
            field_html_params => sub { MoreCustomFields::TimestampedTextarea::_field_html_params(@_); },
        },
        wysiwyg_textarea => {
            label             => 'Multi-Line Text (WYSIWYG)',
            column_def        => 'vclob',
            order             => 201,
            no_default        => 1,
            field_html        => sub { MoreCustomFields::WYSIWYGTextArea::_field_html(); },
        },
        message => {
            label             => 'Message',
            column_def        => 'vclob',
            order             => 210,
            # Disabling "no_default" means that a default *is* allowed.
            #no_default        => 1,
            options_field     => sub { MoreCustomFields::Message::_options_field(); },
            field_html        => sub { MoreCustomFields::Message::_field_html(); },
            field_html_params => sub { MoreCustomFields::Message::_field_html_params(@_); },
        },
        reciprocal_entry => {
            label             => 'Reciprocal Entry Association',
            column_def        => 'vchar',
            order             => 801,
            no_default        => 1,
            options_field     => sub { MoreCustomFields::ReciprocalObject::_options_field(); },
            field_html        => sub { MoreCustomFields::ReciprocalObject::_field_html('entry'); },
            field_html_params => sub { MoreCustomFields::ReciprocalObject::_field_html_params(@_,'entry'); },
        },
        reciprocal_page => {
            label             => 'Reciprocal Page Association',
            column_def        => 'vchar',
            order             => 802,
            no_default        => 1,
            options_field     => sub { MoreCustomFields::ReciprocalObject::_options_field(); },
            field_html        => sub { MoreCustomFields::ReciprocalObject::_field_html('page'); },
            field_html_params => sub { MoreCustomFields::ReciprocalObject::_field_html_params(@_,'page'); },
        },
    };

    # Grab all registered types of assets and add a new custom field for
    # each type. This way the field can be "Selected Images," for example
    # and give the user a chance to include only images and not other types
    # of assets.
    require MT::Asset;
    my $asset_types = MT::Asset->class_labels;
    my @asset_types =
      sort { $asset_types->{$a} cmp $asset_types->{$b} } keys %$asset_types;

    my $order = 2000;
    foreach my $a_type (@asset_types) {
        my $asset_type = $a_type;
        $asset_type =~ s/^asset\.//;

        # The $asset_type 'asset.file' returns a label of "Asset" for some
        # reason, so just correcct that here.
        my $label = ($asset_type eq 'file') 
          ? 'File' 
          : MT::Asset->class_handler($a_type)->class_label;
        $label = 'Selected '. $label . 's';

        $customfield_types->{'selected_' . $a_type . 's'} = {
            label             => $label,
            asset_type        => $a_type,
            no_default        => 1,
            column_def        => 'vchar',
            order             => $order,
            # Not setting the context (making the context system-wide)
            # results in a Selected Asset custom field that is usable at the
            # blog level as normal. However, when trying to use it for system-
            # level objects (authors), a a permissions error pops up. I
            # didn't investigate more because I don't need system-level
            # support.
            context           => 'blog',
            sanitize          => \&MT::Util::sanitize_asset,
            field_html        => sub { MoreCustomFields::SelectedAssets::_field_html(); },
            field_html_params => sub {
                # Add "asset_type" and "asset_type_label" to the template
                # parameters before going to _field_html_params.
                $_[2]->{asset_type} = $asset_type;
                $_[2]->{asset_type_label} = MT->translate($asset_type);
                MoreCustomFields::SelectedAssets::_field_html_params(@_); 
            },
        };
        # Increment $order so that each custom field has a unique position.
        $order += 1;
    }
    
    # $customfield_types now holds all the different asset types, as well
    # as the other custom field types defined above.
    return $customfield_types;
}

# This is responsible for loading support files in the head of the site.
sub update_template {
    my ($cb, $app, $template) = @_;

    # Only update the necessary templates -- entry, page, category, folder,
    # and author. All of which happen to be easily identifiable as using the
    # mode `view`.
    return unless $app->param('__mode') eq 'view'
        || $app->param('__mode') eq 'cfg_prefs'; # For MT5 Website & Blog objects.

    my $old = q{</head>};
    my $new;

    # Check if jQuery has already been loaded. If it has, just skip this.
    unless ( $$template =~ m/jquery/) {
        # Include jQuery as part of the js_include, used on the 
        # include/header.tmpl, which is used on all pages.
        $new = <<'END';
    <script type="text/javascript" src="<mt:Var name="static_uri">jquery/jquery.js"></script>
END
    }

    # MT4 also needs jQuery UI for the draggable Entry/Page/Asset Objects.
    $new .= q{<script type="text/javascript" src="<mt:Var name="static_uri">support/plugins/morecustomfields/jquery-ui-1.8.19.custom.min.js"></script>}
        if $app->product_version =~ /^4/;

    # Insert the More Custom Fields javascript.
    $new .= <<'END';
    <script type="text/javascript" src="<mt:Var name="static_uri">support/plugins/morecustomfields/app.js"></script>
    <link rel="stylesheet" type="text/css" href="<mt:Var name="static_uri">support/plugins/morecustomfields/app.css" />
END

    $$template =~ s/$old/$new$old/;
}

sub post_save {
    my ($cb, $app, $obj) = @_;
    return unless $app->isa('MT::App');

    foreach ($app->param) {
        # The "beacon" is used to always grab the checkboxes. After all are 
        # captured, then we can check their status (checked or not).
        if(m/^customfield_(.*?)_checkboxgroupcf_(.*?)_cb_beacon$/) { 
            MoreCustomFields::CheckboxGroup::_save({
                app    => $app,
                object => $obj,
                count  => $2,
            });
        }

        # Find the Radio Buttons with Input field.
        elsif (m/^customfield_(.*?)_radiobuttonswithinput$/) {
            MoreCustomFields::RadioButtonsWithInput::_save({
                app            => $app,
                object         => $obj,
                field_basename => $1,
            });
        }

        # Find the Multi-Use Single Line Text Group field
        # The "beacon" is used to always grab the text field. This will catch
        # an empty text field.
        elsif (m/^customfield_(.*?)_multiusesinglelinetextgroupcf_(.*?)_cb_beacon$/) {
            MoreCustomFields::SingleLineTextGroup::_save({
                app             => $app,
                object          => $obj,
                user_field_name => $2,
            });
        }

        # Find the Multi-Use Time Stamped Multi-Line Text Group field
        # The "beacon" is used to always grab the text field. This will catch
        # an empty text field.
        elsif (m/^customfield_(.*?)_multiusetimestampedmultilinetextcf_cb_beacon$/) {
            MoreCustomFields::TimestampedTextarea::_save({
                app            => $app,
                object         => $obj,
                field_basename => $1,
            });
        }

        # Find the Reciprocal Entry Association field.
        elsif (m/^customfield_(.*?)_reciprocal_(entry|page)$/) {
            MoreCustomFields::ReciprocalObject::_save({
                app            => $app,
                object         => $obj,
                field_basename => $1,
            });
        }
    }
    
    1; # Callbacks should always return true
}

1;

__END__
