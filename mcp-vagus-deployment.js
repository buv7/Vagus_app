#!/usr/bin/env node

/**
 * MCP Server for Vagus App Deployment Control
 * Provides full control over GitHub, Vercel, and Supabase deployments
 */

const { Server } = require('@modelcontextprotocol/sdk/server/index.js');
const { StdioServerTransport } = require('@modelcontextprotocol/sdk/server/stdio.js');
const { CallToolRequestSchema, ListToolsRequestSchema } = require('@modelcontextprotocol/sdk/types.js');
const { exec } = require('child_process');
const { promisify } = require('util');
const fs = require('fs').promises;
const path = require('path');

const execAsync = promisify(exec);

class VagusDeploymentMCP {
  constructor() {
    this.server = new Server(
      {
        name: 'vagus-deployment',
        version: '1.0.0',
      },
      {
        capabilities: {
          tools: {},
        },
      }
    );

    this.setupToolHandlers();
  }

  setupToolHandlers() {
    this.server.setRequestHandler(ListToolsRequestSchema, async () => ({
      tools: [
        {
          name: 'deploy_to_github',
          description: 'Deploy all changes to GitHub (commit, push all branches)',
          inputSchema: {
            type: 'object',
            properties: {
              message: {
                type: 'string',
                description: 'Commit message',
                default: 'Deploy latest changes'
              },
              pushAll: {
                type: 'boolean',
                description: 'Push to all branches',
                default: true
              }
            }
          }
        },
        {
          name: 'deploy_to_vercel',
          description: 'Deploy to Vercel production (vagus.fit)',
          inputSchema: {
            type: 'object',
            properties: {
              build: {
                type: 'boolean',
                description: 'Build Flutter web app before deployment',
                default: true
              },
              production: {
                type: 'boolean',
                description: 'Deploy to production domain',
                default: true
              }
            }
          }
        },
        {
          name: 'deploy_to_supabase',
          description: 'Apply database migrations to Supabase',
          inputSchema: {
            type: 'object',
            properties: {
              connectionString: {
                type: 'string',
                description: 'Supabase connection string',
                default: 'postgresql://postgres.kydrpnrmqbedjflklgue:X.7achoony.X@aws-0-eu-central-1.pooler.supabase.com:5432/postgres'
              },
              safe: {
                type: 'boolean',
                description: 'Use safe migration mode',
                default: true
              }
            }
          }
        },
        {
          name: 'full_deployment',
          description: 'Complete deployment pipeline: GitHub + Vercel + Supabase',
          inputSchema: {
            type: 'object',
            properties: {
              message: {
                type: 'string',
                description: 'Deployment message',
                default: 'Full deployment: GitHub + Vercel + Supabase'
              },
              buildFlutter: {
                type: 'boolean',
                description: 'Build Flutter web app',
                default: true
              }
            }
          }
        },
        {
          name: 'check_deployment_status',
          description: 'Check status of all deployments',
          inputSchema: {
            type: 'object',
            properties: {}
          }
        },
        {
          name: 'build_flutter_web',
          description: 'Build Flutter web application',
          inputSchema: {
            type: 'object',
            properties: {
              outputDir: {
                type: 'string',
                description: 'Output directory for build',
                default: 'web'
              }
            }
          }
        },
        {
          name: 'run_database_migration',
          description: 'Run specific database migration',
          inputSchema: {
            type: 'object',
            properties: {
              migrationFile: {
                type: 'string',
                description: 'Migration file to run'
              },
              connectionString: {
                type: 'string',
                description: 'Database connection string'
              }
            }
          }
        }
      ]
    }));

    this.server.setRequestHandler(CallToolRequestSchema, async (request) => {
      const { name, arguments: args } = request.params;

      try {
        switch (name) {
          case 'deploy_to_github':
            return await this.deployToGitHub(args);
          case 'deploy_to_vercel':
            return await this.deployToVercel(args);
          case 'deploy_to_supabase':
            return await this.deployToSupabase(args);
          case 'full_deployment':
            return await this.fullDeployment(args);
          case 'check_deployment_status':
            return await this.checkDeploymentStatus();
          case 'build_flutter_web':
            return await this.buildFlutterWeb(args);
          case 'run_database_migration':
            return await this.runDatabaseMigration(args);
          default:
            throw new Error(`Unknown tool: ${name}`);
        }
      } catch (error) {
        return {
          content: [
            {
              type: 'text',
              text: `Error: ${error.message}`
            }
          ]
        };
      }
    });
  }

  async deployToGitHub(args) {
    const { message = 'Deploy latest changes', pushAll = true } = args;
    
    try {
      // Stage all changes
      await execAsync('git add -A');
      
      // Commit changes
      await execAsync(`git commit -m "${message}"`);
      
      // Push to all branches if requested
      if (pushAll) {
        await execAsync('git push origin --all');
        await execAsync('git push origin --tags');
      } else {
        await execAsync('git push origin main');
      }
      
      return {
        content: [
          {
            type: 'text',
            text: `✅ Successfully deployed to GitHub!\n- Committed: ${message}\n- Pushed to all branches: ${pushAll}`
          }
        ]
      };
    } catch (error) {
      throw new Error(`GitHub deployment failed: ${error.message}`);
    }
  }

  async deployToVercel(args) {
    const { build = true, production = true } = args;
    
    try {
      let result = '';
      
      // Build Flutter web app if requested
      if (build) {
        result += '🔨 Building Flutter web app...\n';
        await execAsync('flutter build web');
        result += '✅ Flutter web build completed\n';
      }
      
      // Deploy to Vercel
      result += '🚀 Deploying to Vercel...\n';
      const deployCmd = production ? 'npx vercel --prod --yes' : 'npx vercel --yes';
      const { stdout, stderr } = await execAsync(deployCmd);
      
      result += `✅ Vercel deployment completed\n`;
      result += `Output: ${stdout}`;
      
      if (stderr) {
        result += `\nWarnings: ${stderr}`;
      }
      
      return {
        content: [
          {
            type: 'text',
            text: result
          }
        ]
      };
    } catch (error) {
      throw new Error(`Vercel deployment failed: ${error.message}`);
    }
  }

  async deployToSupabase(args) {
    const { 
      connectionString = 'postgresql://postgres.kydrpnrmqbedjflklgue:X.7achoony.X@aws-0-eu-central-1.pooler.supabase.com:5432/postgres',
      safe = true 
    } = args;
    
    try {
      let result = '🗄️ Applying Supabase migrations...\n';
      
      if (safe) {
        // Use safe migration
        const migrationFile = 'supabase/migrations/20251013120001_safe_schema_updates.sql';
        const migration = await fs.readFile(migrationFile, 'utf8');
        
        const { Client } = require('pg');
        const client = new Client({
          connectionString,
          ssl: { rejectUnauthorized: false }
        });
        
        await client.connect();
        await client.query(migration);
        await client.end();
        
        result += '✅ Safe schema updates applied successfully\n';
      } else {
        // Use Supabase CLI
        const { stdout, stderr } = await execAsync(`npx supabase db push --db-url "${connectionString}" --include-all`);
        result += `✅ Supabase migrations applied\n${stdout}`;
        if (stderr) result += `\nWarnings: ${stderr}`;
      }
      
      return {
        content: [
          {
            type: 'text',
            text: result
          }
        ]
      };
    } catch (error) {
      throw new Error(`Supabase deployment failed: ${error.message}`);
    }
  }

  async fullDeployment(args) {
    const { message = 'Full deployment: GitHub + Vercel + Supabase', buildFlutter = true } = args;
    
    try {
      let result = '🚀 Starting full deployment pipeline...\n\n';
      
      // 1. GitHub deployment
      result += '1️⃣ Deploying to GitHub...\n';
      const githubResult = await this.deployToGitHub({ message, pushAll: true });
      result += githubResult.content[0].text + '\n\n';
      
      // 2. Build Flutter if requested
      if (buildFlutter) {
        result += '2️⃣ Building Flutter web app...\n';
        const buildResult = await this.buildFlutterWeb({});
        result += buildResult.content[0].text + '\n\n';
      }
      
      // 3. Vercel deployment
      result += '3️⃣ Deploying to Vercel...\n';
      const vercelResult = await this.deployToVercel({ build: false, production: true });
      result += vercelResult.content[0].text + '\n\n';
      
      // 4. Supabase deployment
      result += '4️⃣ Applying Supabase migrations...\n';
      const supabaseResult = await this.deployToSupabase({ safe: true });
      result += supabaseResult.content[0].text + '\n\n';
      
      result += '🎉 Full deployment completed successfully!';
      
      return {
        content: [
          {
            type: 'text',
            text: result
          }
        ]
      };
    } catch (error) {
      throw new Error(`Full deployment failed: ${error.message}`);
    }
  }

  async checkDeploymentStatus() {
    try {
      let result = '📊 Deployment Status Check\n\n';
      
      // Check Git status
      try {
        const { stdout } = await execAsync('git status --porcelain');
        if (stdout.trim()) {
          result += '⚠️  Git: Uncommitted changes detected\n';
        } else {
          result += '✅ Git: Working directory clean\n';
        }
      } catch (error) {
        result += `❌ Git: ${error.message}\n`;
      }
      
      // Check Flutter build
      try {
        await execAsync('flutter --version');
        result += '✅ Flutter: Available\n';
      } catch (error) {
        result += `❌ Flutter: ${error.message}\n`;
      }
      
      // Check Vercel CLI
      try {
        const { stdout } = await execAsync('npx vercel --version');
        result += `✅ Vercel CLI: ${stdout.trim()}\n`;
      } catch (error) {
        result += `❌ Vercel CLI: ${error.message}\n`;
      }
      
      // Check Supabase CLI
      try {
        const { stdout } = await execAsync('npx supabase --version');
        result += `✅ Supabase CLI: ${stdout.trim()}\n`;
      } catch (error) {
        result += `❌ Supabase CLI: ${error.message}\n`;
      }
      
      return {
        content: [
          {
            type: 'text',
            text: result
          }
        ]
      };
    } catch (error) {
      throw new Error(`Status check failed: ${error.message}`);
    }
  }

  async buildFlutterWeb(args) {
    const { outputDir = 'web' } = args;
    
    try {
      const { stdout, stderr } = await execAsync('flutter build web');
      
      return {
        content: [
          {
            type: 'text',
            text: `✅ Flutter web build completed successfully!\nOutput directory: ${outputDir}\n${stdout}${stderr ? `\nWarnings: ${stderr}` : ''}`
          }
        ]
      };
    } catch (error) {
      throw new Error(`Flutter build failed: ${error.message}`);
    }
  }

  async runDatabaseMigration(args) {
    const { migrationFile, connectionString } = args;
    
    if (!migrationFile) {
      throw new Error('Migration file is required');
    }
    
    try {
      const migration = await fs.readFile(migrationFile, 'utf8');
      
      const { Client } = require('pg');
      const client = new Client({
        connectionString,
        ssl: { rejectUnauthorized: false }
      });
      
      await client.connect();
      await client.query(migration);
      await client.end();
      
      return {
        content: [
          {
            type: 'text',
            text: `✅ Migration ${migrationFile} applied successfully!`
          }
        ]
      };
    } catch (error) {
      throw new Error(`Migration failed: ${error.message}`);
    }
  }

  async run() {
    const transport = new StdioServerTransport();
    await this.server.connect(transport);
    console.error('Vagus Deployment MCP server running on stdio');
  }
}

// Start the server
const server = new VagusDeploymentMCP();
server.run().catch(console.error);
