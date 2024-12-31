# genai-pg-context

<p>
<a href=""><img src="https://img.shields.io/badge/postgresql-15+-blue.svg" alt="PostgreSQL version" height="18"></a>
<a href="https://github.com/olirice/genai-pg-context/blob/master/LICENSE"><img src="https://img.shields.io/pypi/l/markdown-subtemplate.svg" alt="License" height="18"></a>
<a href="https://github.com/olirice/genai-pg-context/actions"><img src="https://github.com/olirice/genai-pg-context/actions/workflows/test.yml/badge.svg" alt="tests" height="18"></a>
</p>

---

**Source Code**: <a href="https://github.com/olirice/genai-pg-context" target="_blank">https://github.com/olirice/genai-pg-context</a>

---

genai-pg-context develops a single SQL query [context.sql](context.sql) that can be used to extract "context" for Generative AI tools from a Postgres database for example v0, bolt and lovable. A better long term solution would include pagination, partial fetches, and globally unique cacheable ids for all entities.

See [context.sql](context.sql) for the context query (remove the function wrapper)

## Usage

## Development

Supabase PostgreSQL 15+

Setup:

```sh
git clone https://github.com/olirice/genai-pg-context.git
cd genai-pg-context
```

## Tests

Ensure postgres is on your path.

To run the test suite:

```sh
./bin/installcheck
```
