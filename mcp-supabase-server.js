#!/usr/bin/env node

/**
 * Custom MCP Supabase Server for VAGUS App
 * This provides enhanced database access and querying capabilities
 */

const { Server } = require('@modelcontextprotocol/sdk/server/index.js');
const { StdioServerTransport } = require('@modelcontextprotocol/sdk/server/stdio.js');
const { CallToolRequestSchema, ListToolsRequestSchema } = require('@modelcontextprotocol/sdk/types.js');
const { Client } = require('pg');

// Database connection configuration
const dbConfig = {
  host: process.env.SUPABASE_DB_HOST || 'aws-0-eu-central-1.pooler.supabase.com',
  port: process.env.SUPABASE_DB_PORT || 5432,
  database: process.env.SUPABASE_DB_NAME || 'postgres',
  user: process.env.SUPABASE_DB_USERNAME || 'postgres.kydrpnrmqbedjflklgue',
  password: process.env.SUPABASE_DB_PASSWORD || 'X.7achoony.X',
  ssl: process.env.SUPABASE_DB_SSL === 'true' || true,
};

const server = new Server(
  {
    name: 'vagus-supabase-mcp-server',
    version: '1.0.0',
  },
  {
    capabilities: {
      tools: {},
    },
  }
);

// Database connection helper
async function getDbConnection() {
  const client = new Client(dbConfig);
  await client.connect();
  return client;
}

// List available tools
server.setRequestHandler(ListToolsRequestSchema, async () => {
  return {
    tools: [
      {
        name: 'query_database',
        description: 'Execute SQL queries on the VAGUS Supabase database',
        inputSchema: {
          type: 'object',
          properties: {
            query: {
              type: 'string',
              description: 'SQL query to execute',
            },
          },
          required: ['query'],
        },
      },
      {
        name: 'list_tables',
        description: 'List all tables in the database',
        inputSchema: {
          type: 'object',
          properties: {},
        },
      },
      {
        name: 'describe_table',
        description: 'Get detailed information about a specific table',
        inputSchema: {
          type: 'object',
          properties: {
            table_name: {
              type: 'string',
              description: 'Name of the table to describe',
            },
          },
          required: ['table_name'],
        },
      },
      {
        name: 'get_user_stats',
        description: 'Get user statistics for the VAGUS app',
        inputSchema: {
          type: 'object',
          properties: {},
        },
      },
      {
        name: 'get_coach_clients',
        description: 'Get coach-client relationships',
        inputSchema: {
          type: 'object',
          properties: {
            coach_id: {
              type: 'string',
              description: 'Optional coach ID to filter by',
            },
          },
        },
      },
      {
        name: 'get_ai_usage_stats',
        description: 'Get AI usage statistics',
        inputSchema: {
          type: 'object',
          properties: {
            user_id: {
              type: 'string',
              description: 'Optional user ID to filter by',
            },
          },
        },
      },
      {
        name: 'check_database_health',
        description: 'Check database health and performance',
        inputSchema: {
          type: 'object',
          properties: {},
        },
      },
    ],
  };
});

// Handle tool calls
server.setRequestHandler(CallToolRequestSchema, async (request) => {
  const { name, arguments: args } = request.params;

  try {
    switch (name) {
      case 'query_database':
        return await executeQuery(args.query);

      case 'list_tables':
        return await listTables();

      case 'describe_table':
        return await describeTable(args.table_name);

      case 'get_user_stats':
        return await getUserStats();

      case 'get_coach_clients':
        return await getCoachClients(args.coach_id);

      case 'get_ai_usage_stats':
        return await getAIUsageStats(args.user_id);

      case 'check_database_health':
        return await checkDatabaseHealth();

      default:
        throw new Error(`Unknown tool: ${name}`);
    }
  } catch (error) {
    return {
      content: [
        {
          type: 'text',
          text: `Error executing ${name}: ${error.message}`,
        },
      ],
    };
  }
});

// Tool implementations
async function executeQuery(query) {
  const client = await getDbConnection();
  try {
    const result = await client.query(query);
    return {
      content: [
        {
          type: 'text',
          text: JSON.stringify(result.rows, null, 2),
        },
      ],
    };
  } finally {
    await client.end();
  }
}

async function listTables() {
  const client = await getDbConnection();
  try {
    const result = await client.query(`
      SELECT 
        table_name,
        table_type
      FROM information_schema.tables 
      WHERE table_schema = 'public' 
      ORDER BY table_name
    `);
    
    return {
      content: [
        {
          type: 'text',
          text: `Tables in VAGUS database:\n${result.rows.map(row => `- ${row.table_name} (${row.table_type})`).join('\n')}`,
        },
      ],
    };
  } finally {
    await client.end();
  }
}

async function describeTable(tableName) {
  const client = await getDbConnection();
  try {
    const result = await client.query(`
      SELECT 
        column_name,
        data_type,
        is_nullable,
        column_default
      FROM information_schema.columns 
      WHERE table_name = $1 AND table_schema = 'public'
      ORDER BY ordinal_position
    `, [tableName]);
    
    if (result.rows.length === 0) {
      return {
        content: [
          {
            type: 'text',
            text: `Table '${tableName}' not found in public schema`,
          },
        ],
      };
    }
    
    const columns = result.rows.map(row => 
      `- ${row.column_name}: ${row.data_type}${row.is_nullable === 'NO' ? ' NOT NULL' : ''}${row.column_default ? ` DEFAULT ${row.column_default}` : ''}`
    ).join('\n');
    
    return {
      content: [
        {
          type: 'text',
          text: `Table: ${tableName}\nColumns:\n${columns}`,
        },
      ],
    };
  } finally {
    await client.end();
  }
}

async function getUserStats() {
  const client = await getDbConnection();
  try {
    const result = await client.query(`
      SELECT 
        role,
        COUNT(*) as user_count
      FROM profiles 
      GROUP BY role
      ORDER BY user_count DESC
    `);
    
    return {
      content: [
        {
          type: 'text',
          text: `User Statistics:\n${result.rows.map(row => `- ${row.role}: ${row.user_count} users`).join('\n')}`,
        },
      ],
    };
  } finally {
    await client.end();
  }
}

async function getCoachClients(coachId) {
  const client = await getDbConnection();
  try {
    let query = `
      SELECT 
        cc.coach_id,
        p1.name as coach_name,
        cc.client_id,
        p2.name as client_name,
        cc.status,
        cc.created_at
      FROM user_coach_links cc
      JOIN profiles p1 ON cc.coach_id = p1.id
      JOIN profiles p2 ON cc.client_id = p2.id
    `;
    
    const params = [];
    if (coachId) {
      query += ' WHERE cc.coach_id = $1';
      params.push(coachId);
    }
    
    query += ' ORDER BY cc.created_at DESC LIMIT 20';
    
    const result = await client.query(query, params);
    
    return {
      content: [
        {
          type: 'text',
          text: `Coach-Client Relationships:\n${result.rows.map(row => 
            `- Coach: ${row.coach_name} → Client: ${row.client_name} (${row.status})`
          ).join('\n')}`,
        },
      ],
    };
  } finally {
    await client.end();
  }
}

async function getAIUsageStats(userId) {
  const client = await getDbConnection();
  try {
    let query = `
      SELECT 
        au.user_id,
        p.name as user_name,
        au.month,
        au.year,
        au.tokens_used,
        au.request_count,
        au.created_at
      FROM ai_usage au
      JOIN profiles p ON au.user_id = p.id
    `;
    
    const params = [];
    if (userId) {
      query += ' WHERE au.user_id = $1';
      params.push(userId);
    }
    
    query += ' ORDER BY au.created_at DESC LIMIT 10';
    
    const result = await client.query(query, params);
    
    return {
      content: [
        {
          type: 'text',
          text: `AI Usage Statistics:\n${result.rows.map(row => 
            `- ${row.user_name}: ${row.tokens_used} tokens, ${row.request_count} requests (${row.month}/${row.year})`
          ).join('\n')}`,
        },
      ],
    };
  } finally {
    await client.end();
  }
}

async function checkDatabaseHealth() {
  const client = await getDbConnection();
  try {
    // Check table sizes
    const tableSizes = await client.query(`
      SELECT 
        schemaname,
        tablename,
        pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) as size
      FROM pg_tables 
      WHERE schemaname = 'public'
      ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC
      LIMIT 10
    `);
    
    // Check connection count
    const connections = await client.query(`
      SELECT COUNT(*) as active_connections
      FROM pg_stat_activity 
      WHERE state = 'active'
    `);
    
    return {
      content: [
        {
          type: 'text',
          text: `Database Health Check:\n\nTable Sizes:\n${tableSizes.rows.map(row => 
            `- ${row.tablename}: ${row.size}`
          ).join('\n')}\n\nActive Connections: ${connections.rows[0].active_connections}`,
        },
      ],
    };
  } finally {
    await client.end();
  }
}

// Start the server
async function main() {
  const transport = new StdioServerTransport();
  await server.connect(transport);
  console.error('VAGUS Supabase MCP server running on stdio');
}

main().catch(console.error);
