# Modesty

Modesty is a really simple metrics and A/B testing framework that doesn't
really do all that much. It was inspired by [assaf's Vanity](http://github.com/assaf/vanity).

## Metrics
A metric keeps track of things that happen, and ties in and disaggregates many
different types of data. Define a metric with:

    Modesty.new_metric :foo

Your metric will now be available as `Modesty.metrics[:foo]`. You can track it
with:

    Modesty.track! :foo

You can get a raw count with:

    Modesty.metrics[:foo].count

You can track multiple counts with `Modesty.track! :foo, 7`, or, if you
prefer, `Modesty.track! :foo, :count => 7`.

Simple, huh?

You can also pass in any sort of metadata when you track your metric. For
example:

    Modesty.track! :product_page_viewed, :with => {:product_id => 500, :seller_id => 278}

This provides you with a few more granular methods:

    m = Modesty.metrics[:product_page_viewed]

    # number of unique product_ids that were tracked
    m.unique :product_ids

    # the actual ids that were tracked
    m.all :product_ids

    # a hash of {product_id => tracks for this product id}
    m.aggregate_by :product_ids

    # equivalent to aggregate_by(:product_ids).values.histogram
    m.distribution_by :product_ids

### Submetrics
Submetrics are useful for tracking events that are logically tied to their
parent events, but separate. For example, if you're measuring the success
rate of a form submission, you might use something like:

    Modesty.new_metric :my_form do |m|
      m.submetric :success
      m.submetric :failure
    end

Then, when the form is submitted, you can just track one of the submetrics
and the count will bubble up to the parent metric.

    if @post.save
      Modesty.track! :my_form/:success
    else
      Modesty.track! :my_form/:failure
    end

Now you have the number of successes in `Modesty.metrics[:my_form/:success].count` and the total number of form submissions in `Modesty.metrics[:my_form].count`. Nifty, eh?

## Identity
To save you some hassle, Modesty keeps around a global identity in
`Modesty.identity`. You can set the identity with `Modesty.identify! id`,
where `id` is either an integer (i.e. the id of the current user) or `nil` for
guests. When the identity is present, all metrics tracked will get a `:user`
parameter passed in. This makes it really easy to call `m.unique :users` and
such, without having to pass it in every time. To override this, just call:

    Modesty.track! :metric, :with => {:user => other_user}

If you're using Rails, we recommend putting a `before_filter` on
`ApplicationController` that does something akin to `Modesty.identify! viewer.id`.

## Experiments
Experiments are really the point of Modesty. With an experiment, you separate
your users into experiment groups and track how each group performs on a given
set of metrics. Modesty will ensure that:

  * Each group contains roughly the same number of users.
  * Each user has a consistent experience.
  * All specified metrics can be disaggregated by experiment group.

Here's how you make an experiment:

    Modesty.new_experiment :button_size do |e|
      e.metrics :conversion, :view
      e.alternatives :huge, :medium, :small
    end

Then, you can do something like this (in a controller, say):

    button_size = Modesty.experiment :button_size do |e|
      e.group :huge do
        9001
      end
      e.group :medium do
        1337
      end
      e.group :small do
        2
      end
    end

This code will use `Modesty.identity` to determine the appropriate experiment
group, and run the corresponding block.

All your tracking data will automagically be disaggregated into:

    Modesty.metrics[:conversion/:button_size/:huge]
    Modesty.metrics[:conversion/:button_size/:medium]
    Modesty.metrics[:conversion/:button_size/:small]

## Statistics & Reporting

TODO.

## Datastores & Config

Right now there are two datastores available: Redis and a sweet mock Redis for
testing. To switch between them, use:

    Modesty.data = :redis
    Modesty.data = :mock

If you need to pass in more options, use:

    Modesty.set_store :redis, :port => 8888, :host => '123.123.123.1'

## Rails

By default, Modesty looks in configy/modesty.yml for something like:

    datastore:
      type: redis
      port: 6739
      host: localhost

    paths:
      experiments: modesty/experiments
      metrics: modesty/metrics

In this, the default setup, Modesty will look for experiments in
`#{Rails.root}/modesty/experiments`, and metrics in
`#{Rails.root}/modesty/metrics`. If no config file is found, or you omit
something, Modesty will use these settings. Everything in the `datastore:`
stanza (sans `type: redis`) will be passed as options to `Redis.new`.

Have fun!
