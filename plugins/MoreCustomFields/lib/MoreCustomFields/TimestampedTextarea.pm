package MoreCustomFields::TimestampedTextarea;

use strict;

use MT 4.2;
use base qw(MT::Plugin);
use CustomFields::Util qw( get_meta save_meta field_loop _get_html );
use MT::Util qw( relative_date offset_time offset_time_list epoch2ts ts2epoch 
    format_ts encode_html dirify );

sub _field_html {
    return q{
<mt:SetVarTemplate name="invisible_field_template">
    <li>
        <input type="hidden" 
            name="<mt:Var name="field_name">_multiusetimestampedmultilinetextcf_cb_beacon" 
            value="1" />

        <textarea
            name="<mt:var name="field_name">_multiusetimestampedmultilinetextcf_text" 
            id="<mt:var name="field_name">_multiusetimestampedmultilinetextcf_text"
            class="text full-width"></textarea>

        <div class="timestamp">&nbsp;</div>

        <input type="hidden"
            name="<mt:var name="field_name">_multiusetimestampedmultilinetextcf_timestamp" 
            id="<mt:var name="field_name">_multiusetimestampedmultilinetextcf_timestamp"
            value="" />
    </li>
</mt:SetVarTemplate>
<mt:SetVarTemplate name="field_template">
    <li>
        <input type="hidden" 
            name="<mt:Var name="field_name">_multiusetimestampedmultilinetextcf_cb_beacon" 
            value="1" />

        <textarea
            name="<mt:var name="field_name">_multiusetimestampedmultilinetextcf_text" 
            id="<mt:var name="field_name">_multiusetimestampedmultilinetextcf_text"
            class="text full-width"><mt:Var name="ts_text" escape="html"></textarea>

        <div class="timestamp">
            <mt:If name="timestamp">Time stamp: <mt:Var name="timestamp_formatted"></mt:If>
        </div>

        <input type="hidden"
            name="<mt:var name="field_name">_multiusetimestampedmultilinetextcf_timestamp" 
            id="<mt:var name="field_name">_multiusetimestampedmultilinetextcf_timestamp"
            value="<mt:Var name="timestamp" escape="html">" />
    </li>
</mt:SetVarTemplate>

    <script type="text/javascript">

    jQuery(document).ready(function($) {
        // Populate any empty timestamp field.
        jQuery('ul.cf-text-group input[name=<mt:var name="field_name">_multiusetimestampedmultilinetextcf_timestamp]').each(function(index) {
            if ( jQuery(this).val() == '' ) {
                jQuery(this).val( createDate() );
            }
        });
    });
    </script>
<mt:Loop name="text_group_loop">
    <mt:Var name="__counter__" setvar="text_group_counter">
    <mt:If name="__first__">
        <div id="<mt:Var name="field_name">_multiusetimestampedmultilinetextcf_container">
    </mt:If>
    <mt:Loop name="fields_loop">
        <mt:If name="__first__">
            <ul class="cf-text-group">
        </mt:If>
                <mt:Var name="field_template">
        <mt:If name="__last__">
                <li class="cf-text-group-delete-button">
                    <a href="javascript:void(0)"
                        class="icon-left icon-error">
                        Delete this <mt:Var name="text_group_label"> field
                    </a>
                </li>
            </ul>
        </mt:If>
    </mt:Loop>
    <mt:If name="__last__">
        </div>
        <p id="create-new-link">
            <a href="javascript:void(0);" 
                onclick="addGroup('<mt:Var name="field_name">_multiusetimestampedmultilinetextcf_container','<mt:Var name="field_name">')" 
                class="icon-left icon-create">
                Add another <mt:Var name="text_group_label"> field
            </a>
        </p>
    </mt:If>
    <!-- This is to create the "hidden" group, used for the "add another" link. -->
    <mt:If name="__last__">
        <mt:Loop name="fields_loop">
            <mt:If name="__first__">
                <ul class="cf-text-group"
                    style="display: none;"
                    id="<mt:Var name="field_name">_multiusetimestampedmultilinetextcf_invisible-field">
            </mt:If>
                    <mt:Var name="invisible_field_template">
            <mt:If name="__last__">
                    <li class="cf-text-group-delete-button">
                        <a href="javascript:void(0)"
                            class="icon-left icon-error">
                            Delete this <mt:Var name="text_group_label"> field
                        </a>
                    </li>
                </ul>
            </mt:If>
        </mt:Loop>
    </mt:If>
</mt:Loop>
    };
}



# The principle thing to do here is add the field value to the options loop.
sub _field_html_params {
    my ($key, $tmpl_key, $tmpl_param) = @_;
    my $app = MT->instance;

    my @group_loop;

    # Step through the saved YAML to populate fields.
    my $option_loop = $tmpl_param->{option_loop};

    # Only proceed if there is saved data to process.
    if ($tmpl_param->{field_value}) {

        # The field values are saved as YAML. Grab the values, convert them to
        # a string, and push them into the options loop.
        my $yaml = YAML::Tiny->new;
        $yaml = YAML::Tiny->read_string( $tmpl_param->{field_value} );

        # The $field_name is the custom field basename.
        foreach my $field_name ( keys %{$yaml->[0]} ) {
            my $field = $yaml->[0]->{$field_name};

            # The $group_num is the group order/parent of the values. Sort it
            # so that they are displayed in the order they were saved.
            foreach my $group_num ( sort keys %{$field} ) {
                my @fields_loop;
                
                # Format the date shown to users. The field stores a 
                # punctuation-less timestamp, so it needs to be made friendly.
                my $formatted_ts = format_ts( 
                    "%x %X", 
                    $field->{$group_num}->{timestamp}, 
                    $app->blog, 
                    $app && $app->user ? $app->user->preferred_language : undef 
                );
                
                # Now push the saved field value into the option loop.
                push @fields_loop, {
                    ts_text             => $field->{$group_num}->{text},
                    timestamp           => $field->{$group_num}->{timestamp},
                    timestamp_formatted => $formatted_ts,
                };
                push @group_loop, {
                    fields_loop => \@fields_loop,
                };
            }
        }
    }

    # Even if there was no saved data to recall, we want to provide a
    # starting point for the user to enter data. Populate that starting
    # point.
    if ( ! scalar @group_loop ) {
        my @fields_loop = [{
            ts_text   => '',
            timestamp => '',
        }];

        push @group_loop, {
            fields_loop => \@fields_loop,
        };
    }

    $tmpl_param->{text_group_loop} = \@group_loop;

    # Get the basename of this customfield so that we can show the field's
    # display name next to the "add group" and "delete group" links.
    my $basename = $tmpl_param->{field_name};
    $basename =~ s/^customfield_(.*)$/$1/;
    my $field = MT->model('field')->load({
        #Don't grab the blog_id because that keeps system-wide setting from working ok...
        #blog_id => $app->blog->id || '0',
        basename => $basename,
    });
    if ($field) {
        $tmpl_param->{text_group_label} = $field->name;
    }
}

# This is called by MoreCustomFields::Plugin::post_save, which is the 
# post-save callback handler. Save the data for this custom field type.
sub _save {
    my ($arg_ref) = @_;
    my $app            = $arg_ref->{app};
    my $obj            = $arg_ref->{object};
    my $field_basename = $arg_ref->{field_basename};

    # Build the field names used in this field type.
    my $field_name_text = 'customfield_' . $field_basename
        . '_multiusetimestampedmultilinetextcf_text';
    my $field_name_timestamp = 'customfield_' . $field_basename
        . '_multiusetimestampedmultilinetextcf_timestamp';

    # Look at the individual text field in the group to determine if 
    # it's got any text in it to save.
    if( $app->param($field_name_text) ) { 

        # Save the text values to an array. Since there is text, we know that
        # there is also timestamps to accompany that text.
        my @field_data_text      = $app->param($field_name_text);
        my @field_data_timestamp = $app->param($field_name_timestamp);

        # ...and note the size of the array. We use this to see if the last 
        # text group might be empty
        my $last_group = scalar @field_data_text;

        # Use a group number to hold each group of text boxes together.
        my $group_num = 1;

        # If $last_group is 0, then it means there is no data to save. The 
        # user is probably trying to delete all data, so we need to "write"
        # nothing so that the customfield erases any previously-saved data.
        if ($last_group == 0) {
            $app->param('customfield_' . $field_basename, '');
        }

        foreach my $field_text ( @field_data_text ) {

            # Is this the last text group?
            if ( $last_group == $group_num ) {
                # This is the last text group. Is there a value saved, or is
                # it just an emtpy field? If empty, just give up.
                if ($field_text eq '') {
                    next;
                }
            }

            # Store this field's data as YAML.
            my $yaml = YAML::Tiny->new;

            # If any options for this CF have already been read and set,
            # grab them so we can just continue appending to them.
            if ( $app->param('customfield_' . $field_basename) ) {
                $yaml = YAML::Tiny->read_string( 
                            $app->param('customfield_' . $field_basename) );
            }

            # Grab the timestamp (if it exists) or build a new one.
            my $ts = shift @field_data_timestamp;
            if ( !$ts ){
                my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) 
                    = localtime(time);
                $year += 1900;
                $mon  += 1;
                $ts = $year . sprintf("%02d", $mon) . sprintf("%02d", $mday) 
                    . sprintf("%02d", $hour) . sprintf("%02d", $min) 
                    . sprintf("%02d", $sec);

                # Finally, format the timestamp according to the user prefs.
                # (Is this actually necessary? The $ts above is probably all
                # that is needed, I think.)
                # $ts = format_ts( 
                #     "%Y%m%d%H%M%S", 
                #     $ts, 
                #     $app->blog, 
                #     $app && $app->user ? $app->user->preferred_language : undef 
                # );
            }

            # Write the YAML.
            $yaml->[0]->{$field_basename}->{$group_num}->{text} = $field_text;
            $yaml->[0]->{$field_basename}->{$group_num}->{timestamp} = $ts;
            # Turn that YAML into a plain old string.
            my $result = $yaml->write_string();

            # Save the new result to the *real* field name, which
            # should be written to the DB.
            $app->param('customfield_' . $field_basename, $result);

            # Increment the group number so that the next text group 
            # gets its own YAML key.
            $group_num++;
        }
    }
    # Destory the specially-assembled fields, because they make MT barf.
    $app->delete_param($field_name_text);
    $app->delete_param($field_name_timestamp);
    $app->delete_param(
        'customfield_' . $field_basename
        . '_multiusetimestampedmultilinetextcf_cb_beacon'
    );
}

# This is called by MoreCustomFields::Plugin::_load_tags. Create the tags 
# associated with this custom field type.
sub _create_tags {
    my ($arg_ref) = @_;
    my $tags = $arg_ref->{tags};

    # Grab the field definitions, then use those definitions to load the
    # appropriate objects. Finally, turn those into a block tag.
    my @field_defs = MT->model('field')->load({
        type => 'multi_use_timestamped_multi_line_text',
    });

    foreach my $field_def (@field_defs) {
        my $tag = $field_def->tag;

        # Load the objects (entry, author, whatever) based on the current
        # field definition.
        my $obj_type = $field_def->obj_type;
        my $basename = 'field.' . $field_def->basename;

        # Create the actual tag Use the tag name and append "Loop" to it.
        $tags->{block}->{$tag . 'Loop'} = sub {
            my ( $ctx, $args, $cond ) = @_;

            # Use the $obj_type to figure out what context we're in.
            my $obj = $ctx->stash($obj_type);

            # Then load the saved YAML
            my $yaml = YAML::Tiny->read_string( $obj->$basename );

            # The $field_name is the custom field basename.
            foreach my $field_name ( keys %{$yaml->[0]} ) {
                my $field = $yaml->[0]->{$field_name};

                # Build the output tag content
                my $out = '';
                my $vars = $ctx->{__stash}{vars};
                my $count = 0;

                # Sort the timestamped textarea based on the order it was,
                # added (and by extension saved and therefore timestamped).
                # Sort the fields in ascending date by default, just as they
                # are displayed on the admin interface.
                my @sorted;
                if ($args->{'sort_order'} eq 'descend') {
                    @sorted = sort { 
                        $field->{$b}->{timestamp} <=> $field->{$a}->{timestamp} 
                    } keys %{$field};
                }
                else {
                    @sorted = sort { 
                        $field->{$a}->{timestamp} <=> $field->{$b}->{timestamp} 
                    } keys %{$field};
                }

                # The $group_num is the group order/parent of the values.
                # Sort it so that they are displayed in the order they
                # were saved.
                foreach my $group_num ( @sorted ) {
                    local $vars->{'__first__'} = ($count++ == 0);
                    local $vars->{'__last__'} = ($count == scalar keys %{$field});

                    # Add the keys and values to the output
                    $vars->{text} = $field->{$group_num}->{text};

                    # The following lets the user specify the normal date 
                    # format modifiers. Push the saved timestamp into the "ts"
                    # argument, then _hdlr_date will use that (and any 
                    # "format" supplied as an argument to the loop) to return
                    # a nicely-formatted date-timestamp.
                    $args->{ts} = $field->{$group_num}->{timestamp};
                    require MT::Template::Context;
                    $vars->{date} = MT::Template::Context::_hdlr_date($ctx, $args);

                    defined( $out .= $ctx->slurp( $args, $cond ) ) or return;
                }
                return $out;
            }
        };
    }

    return $tags;
}

1;

__END__
