{#
    Par défaut, dbt préfixe un schema custom avec le schema du target
    (ex: "default_DB_WH_DIGITAL_GAMING"). On veut que +schema:  définisse
    le nom exact de la base ClickHouse, sans préfixe.
#}
{% macro generate_schema_name(custom_schema_name, node) -%}
    {%- if custom_schema_name is none -%}
        {{ target.schema }}
    {%- else -%}
        {{ custom_schema_name | trim }}
    {%- endif -%}
{%- endmacro %}
