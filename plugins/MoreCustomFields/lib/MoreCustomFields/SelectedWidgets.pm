package MoreCustomFields::SelectedWidgets;

use strict;
use warnings;

use MT 4.2;
use base qw(MT::Plugin);

use MT::Util qw( relative_date format_ts );

# Create the options field displayed on the New/Edit Custom Field screen,
# where the field is defined. The $type variable contains either "entries" or
# "pages" to customize the text for the correct field type.
sub _options_field {
    my ($arg_ref) = @_;
    my $type      = $arg_ref->{type};
    my $blog_id = MT->instance->blog ? MT->instance->blog->id : 'all';

    return qq{
    Source: <select name="options" id="options">
        <option value="blog"
            <mt:If name="options" eq="blog">selected="selected"</mt:If>
            >Widgets from this blog only</option>
        <option value="website"
            <mt:If name="options" eq="website">selected="selected"</mt:If>
            >Widgets from this blog and its parent website</option>
        <option value="system"
            <mt:If name="options" eq="system">selected="selected"</mt:If>
            >Widgets from this blog, its parent website, and the system</option>
    </select>
};
}

sub _field_html {
    return q{
<input name="<mt:Var name="field_name">"
    id="<mt:Var name="field_id">"
    class="full-width selected-objects hidden"
    type="hidden"
    value="<mt:Var name="field_value">" />
<input name="<mt:Var name="field_name">_cb_beacon"
    id="<mt:Var name="field_id">"
    class="hidden"
    type="hidden"
    value="1" />

<a
    onclick="jQuery.fn.mtDialog.open('<mt:Var name="script_uri">?__mode=mcf_list_widgets&amp;blog_id=<mt:Var name="blog_id">&amp;options=<mt:Var name="options">&amp;edit_field=<mt:Var name="field_id">')"
    class="button">
    Choose widget
</a>

<ul class="custom-field-selected-objects mcf-listing"
    id="custom-field-selected-objects_<mt:Var name="field_name">">
<mt:Loop name="selected_objects_loop">
    <li id="obj-<mt:Var name="obj_id">" class="sortable">
        <span class="obj-title"><mt:Var name="obj_title"></span>
        <a href="<mt:Var name="script_uri">?__mode=view&amp;_type=<mt:Var name="obj_class">&amp;id=<mt:Var name="obj_id">&amp;blog_id=<mt:Var name="obj_blog_id">"
            class="edit"
            target="_blank"
            title="Edit in a new window."><img 
                src="<mt:Var name="static_uri">images/status_icons/draft.gif"
                width="9" height="9" alt="Edit" /></a>
        <img class="remove"
            alt="Remove selected comment"
            title="Remove selected comment"
            src="<mt:Var name="static_uri">images/status_icons/close.gif"
            width="9" height="9" />
    </li>
</mt:Loop>
</ul>
    };
}

sub _field_html_params {
    my ($key, $tmpl_key, $tmpl_param) = @_;
    my $app = MT->instance;

    my $id       = $app->param('id');
    my $blog     = $app->blog;
    my $blog_id  = $blog ? $blog->id : 0;
    my $obj_type = $tmpl_param->{obj_type};

    my $field_name  = $tmpl_param->{field_name};
    my $field_value = $tmpl_param->{field_value};
    my @obj_ids = split(/,\s?/, $field_value);

    my @obj_ids_loop;
    foreach my $obj_id (@obj_ids) {
        # Verify that $obj_id is a number. If no Selected Widgets are found,
        # it's possible $obj_id could be just a space character, which throws
        # an error. So, this check ensures we always have a valid ID.
        next unless $obj_id =~ m/\d+/;

        my $obj = $app->model('template')->load($obj_id)
            or next;

        push @obj_ids_loop, {
            field_basename => $field_name,
            obj_id         => $obj_id,
            obj_title      => $obj->name,
            obj_class      => 'template',         # For the edit link.
            obj_blog_id    => $obj->blog_id,
        };
    }
    $tmpl_param->{selected_objects_loop} = \@obj_ids_loop;
}

# The SelectedWidegets tag will let you intelligently output the links you
# selected. Use:
# <mt:SelectedWidgets basename="selected_widgets">
#     <h1><mt:Var name="widget_name"></h1>
#     <mt:Include widget="$widget_name">
# </mt:SelectedWidgets>
sub tag_selected_widgets {
    my ($ctx, $args, $cond) = @_;
    my $builder = $ctx->stash('builder');
    my $tokens  = $ctx->stash('tokens');
    my $res     = '';

    # The basename of the custom field you want to grab must be specified.
    # It's used later, to load the field data.
    my $cf_basename = $args->{basename};
    if (!$cf_basename) {
        return $ctx->error( 'The SelectedWidgets block tag requires the '
            . 'basename argument. The basename should be the Selected '
            . 'Widgets Custom Fields field basename.' );
    }

    # Grab the field name with the collected data from above. The basename
    # must be unique so it's a good thing to key off of!
    my $field = CustomFields::Field->load( { basename => $cf_basename, } );
    return $ctx->error('A Selected Comments Custom Field with this basename '
        . 'could not be found.') if !$field;

    my $basename = 'field.'.$field->basename;

    # Use Custom Fields find_stashed_by_type to load the correct object. This
    # will decide if it's an entry, page, category, folder, or author archive,
    # then load the object and return it to us.
    use CustomFields::Template::ContextHandlers;
    my $object = eval {
        CustomFields::Template::ContextHandlers::find_stashed_by_type(
            $ctx, $field->obj_type
        )
    };
    return $ctx->error($@) if $@;

    # Create an array of the widget template IDs held in the field.
    # $object->$basename is the lookup that actually grabs the data.
    my @tmpl_ids = split(/,\s?/, $object->$basename)
      if ($object && $object->$basename);
    my $i = 0;
    my $vars = $ctx->{__stash}{vars} ||= {};
    foreach my $tmpl_id (@tmpl_ids) {
        # Verify that $tmpl_id is a number. If no Selected Widgets are
        # found, it's possible $tmpl_id could be just a space character,
        # which throws an error. So, this check ensures we always have a valid
        # widget/template ID.
        if ($tmpl_id =~ m/\d+/) {
            my $tmpl = MT->model('template')->load({ id => $tmpl_id });

            # Template not found? Let's note it, then move to the next template.
            if (!$tmpl) {
                MT->log({
                    level     => MT->model('log')->INFO(),
                    class     => 'More Custom Fields',
                    category  => 'SelectedWidgets',
                    blog_id   => $field->blog_id,
                    message   => "A widget with the template ID " . $tmpl_id
                        . 'could not be loaded from the Selected Widgets field '
                        . 'with a basename of ' . $$field->basename . '.',
                });
                # Give up and go to the next template ID in the loop.
                next;
            }

            # Assign the meta vars
            local $vars->{__first__} = !$i;
            local $vars->{__last__} = !defined $tmpl_ids[$i + 1];
            local $vars->{__odd__} = ($i % 2) == 0; # 0-based $i
            local $vars->{__even__} = ($i % 2) == 1;
            local $vars->{__counter__} = $i + 1;

            local $vars->{widget_name} = $tmpl->name;

            my $out = $builder->build($ctx, $tokens);
            if (!defined $out) {
                # A error--perhaps a tag used out of context. Report it.
                return $ctx->error( $builder->errstr );
            }
            $res .= $out;
            $i++; # Increment for the meta vars.
        }
    }
    return $res;
}

# This creates the popup dialog that shows the listing of Entries/Pages that
# can be selected.
sub list_content {
    my $app = shift;
    my $q   = $app->can('query') ? $app->query : $app->param;

    my $blog_id    = $q->param('blog_id');
    my $edit_field = $q->param('edit_field');
    my $search     = $q->param('search');
    my $type       = 'template';
    my $options    = $q->param('options');

    die $app->error('Required object type and edit field values missing!')
        unless $type && $edit_field;

    my $plugin = $app->component('MoreCustomFields');

    my %terms = (
        type => 'widget',
    );

    my @blog_ids;
    if ( $options eq 'blog' ) {
        push @blog_ids, $blog_id;
    }
    elsif ( $options eq 'website' ) {
        # Add the current blog, and the parent, if available.
        push @blog_ids, $blog_id;

        my $blog = $app->model('blog')->load({ id => $blog_id });
        if ($blog->parent_id) {
            $blog = $app->model('blog')->load({ id => $blog->parent_id });
            push @blog_ids, $blog->id
                if $blog;
        }
    }
    elsif ( $options eq 'system') {
        # Add the current blog, the system, and the parent, if available.
        push @blog_ids, $blog_id;
        push @blog_ids, '0';

        my $blog = $app->model('blog')->load({ id => $blog_id });
        if ($blog->parent_id) {
            $blog = $app->model('blog')->load({ id => $blog->parent_id });
            push @blog_ids, $blog->id
                if $blog;
        }
    }

    $terms{blog_id} = \@blog_ids;

    my %args = (
        sort      => 'created_on',
        direction => 'descend',
    );

    my $tmpl = $plugin->load_tmpl('widget_list.mtml');

    # For some reason the 'page' _type doesn't get set/picked up for
    # searches, so just set it here.
    $app->param('_type', $type);

    return $app->listing({
        type     => $type,
        template => $tmpl,
        params   => {
            panel_searchable => 1,
            edit_field       => $edit_field,
            search           => $search,
            blog_id          => $blog_id,
            type             => $type,
            options          => $options,
        },
        code => sub {
            my ($obj, $row) = @_;

            $row->{name} = $obj->name || '[Unnamed widget]';

            my $source_blog = $app->model('blog')->load({ id => $obj->blog_id });
            $row->{source} =  $obj->blog_id == 0 ? 'System'
                : $source_blog->name;

            $row->{edit_link} = $app->uri(
                mode => 'view',
                args => {
                    _type   => 'template',
                    id      => $obj->id,
                    blog_id => $obj->blog_id,
                },
            );

            return $row;
        },
        terms => \%terms,
        args  => \%args,
    });
}

# When a Widget has been chosen from the listing popup, insert it into
# the Edit Entry/Edit Page screen.
sub select_object {
    my $app    = shift;
    my $plugin = MT->component('MoreCustomFields');

    my $edit_field = $app->param('edit_field')
        or die $app->errtrans('No edit_field');

    my @ids = split(',', $app->param('id'));

    my @widgets = $app->model('template')->load({ id => \@ids });

    my @inserts_loop;
    foreach my $widget (@widgets) {
        push @inserts_loop, {
            obj_id        => $widget->id,
            obj_title     => $widget->name,
            obj_blog_id   => $widget->blog_id,
            obj_class     => 'template',
            obj_permalink => '',
            edit_field    => $edit_field,
        };
        MT->log("widget: ".$widget->name);
    }

    return $plugin->load_tmpl('insert_object.mtml', { inserts_loop => \@inserts_loop });
}

1;

__END__
