#!/usr/bin/env node

/**
 * Generate Multilingual Fatigue Explanations
 * 
 * This script generates fatigue explanations in English and Arabic for:
 * 1. Intensifiers (based on fatigue_cost)
 * 2. Global fatigue states (low/medium/high)
 * 3. Top exercises (optional)
 * 
 * Translation rules:
 * - Medical-correct, coach-friendly Arabic
 * - Natural Arabic (Modern Standard Arabic, Iraqi-understandable)
 * - AI-ready complete sentences
 * 
 * Usage: node supabase/scripts/generate_fatigue_explanations_multilang.js
 */

const { Client } = require('pg');

// Database connection configuration (use session pooler)
const dbConfig = {
  host: process.env.SUPABASE_DB_HOST || 'aws-0-eu-central-1.pooler.supabase.com',
  port: process.env.SUPABASE_DB_PORT || 5432,
  database: process.env.SUPABASE_DB_NAME || 'postgres',
  user: process.env.SUPABASE_DB_USERNAME || 'postgres.kydrpnrmqbedjflklgue',
  password: process.env.SUPABASE_DB_PASSWORD || 'X.7achoony.X',
  ssl: true,
};

// =====================================================
// FATIGUE COST → FATIGUE LEVEL MAPPING
// =====================================================

function mapFatigueCostToLevel(fatigueCost) {
  if (!fatigueCost) return 'medium'; // Default
  
  const cost = fatigueCost.toLowerCase().trim();
  if (cost === 'low') return 'low';
  if (cost === 'medium' || cost === 'moderate') return 'medium';
  if (cost === 'high' || cost === 'very_high' || cost === 'very high') return 'high';
  return 'medium'; // Default fallback
}

// =====================================================
// GENERATE ENGLISH EXPLANATIONS FOR INTENSIFIERS
// =====================================================

function generateEnglishIntensifierExplanation(intensifier, fatigueLevel) {
  const name = intensifier.name;
  const shortDesc = intensifier.short_desc || '';
  const howTo = intensifier.how_to || '';
  
  // Base explanations by fatigue level
  const baseExplanations = {
    low: {
      title: `Low Fatigue: ${name}`,
      explanation: `${name} creates minimal fatigue accumulation. This method is generally sustainable and can be used frequently without significant recovery demands.`,
      impact: {
        cns: "low",
        joints: "low",
        local_muscle: "low",
        recovery_days: 0.5
      },
      coaching_tip: "This intensifier can be used 2-3 times per week per muscle group without concern."
    },
    medium: {
      title: `Moderate Fatigue: ${name}`,
      explanation: `${name} generates moderate fatigue that accumulates over time. While manageable in isolation, frequency and volume must be monitored to prevent overreaching.`,
      impact: {
        cns: "medium",
        joints: "medium",
        local_muscle: "medium",
        recovery_days: 1
      },
      coaching_tip: "Use this intensifier 1-2 times per week per muscle group, with adequate rest between sessions."
    },
    high: {
      title: `High Fatigue: ${name}`,
      explanation: `${name} creates significant fatigue, heavily taxing both the nervous system and local muscle tissue. Repeated use without adequate recovery increases injury risk and can lead to overreaching.`,
      impact: {
        cns: "high",
        joints: "medium",
        local_muscle: "high",
        recovery_days: 2
      },
      coaching_tip: "Limit use to once per week per muscle group, and avoid combining with other high-fatigue methods."
    }
  };
  
  let base = baseExplanations[fatigueLevel] || baseExplanations.medium;
  
  // Customize based on intensifier characteristics
  if (name.toLowerCase().includes('rest-pause') || name.toLowerCase().includes('rest pause')) {
    base.explanation = `Rest-Pause training heavily taxes the nervous system due to repeated near-failure efforts with short rest periods. This creates high local and systemic fatigue.`;
    base.impact.cns = "high";
    base.impact.local_muscle = "high";
  } else if (name.toLowerCase().includes('myo-reps') || name.toLowerCase().includes('myoreps')) {
    base.explanation = `Myo-Reps create extreme local muscle fatigue through repeated activation sets and mini-sets, while being relatively less demanding on the CNS and joints.`;
    base.impact.local_muscle = "high";
    base.impact.cns = "medium";
    base.impact.joints = "low";
  } else if (name.toLowerCase().includes('drop set')) {
    base.explanation = `Drop sets create high fatigue through immediate continuation after failure with reduced load, heavily stressing both local muscle tissue and connective structures.`;
    base.impact.local_muscle = "high";
    base.impact.joints = "high";
  } else if (name.toLowerCase().includes('cluster')) {
    base.explanation = `Cluster sets generate moderate systemic fatigue by allowing brief recovery between clusters while maintaining high load, making them more sustainable than continuous sets.`;
    base.impact.cns = "medium";
    base.impact.local_muscle = "medium";
  } else if (name.toLowerCase().includes('tempo') || name.toLowerCase().includes('slow eccentric')) {
    base.explanation = `Tempo work and slow eccentrics place increased stress on connective tissues and joints through prolonged time under tension, while creating moderate local muscle fatigue.`;
    base.impact.joints = "high";
    base.impact.local_muscle = "medium";
    base.impact.cns = "low";
  } else if (name.toLowerCase().includes('isometric')) {
    base.explanation = `Isometric holds primarily stress connective tissues and joints through sustained loading, with relatively low metabolic and CNS demands.`;
    base.impact.joints = "high";
    base.impact.local_muscle = "low";
    base.impact.cns = "low";
  } else if (name.toLowerCase().includes('partial')) {
    base.explanation = `Partial reps can reduce joint stress while maintaining muscle tension, creating moderate local fatigue with lower systemic demands.`;
    base.impact.joints = "low";
    base.impact.local_muscle = "medium";
  }
  
  return base;
}

// =====================================================
// GENERATE ARABIC EXPLANATIONS FOR INTENSIFIERS
// =====================================================

function generateArabicIntensifierExplanation(intensifier, fatigueLevel) {
  const name = intensifier.name;
  
  // Base Arabic explanations by fatigue level
  const baseExplanations = {
    low: {
      title: `إجهاد منخفض: ${name}`,
      explanation: `${name} يولد إجهادًا قليلاً. هذه الطريقة قابلة للاستخدام بشكل متكرر دون متطلبات استشفاء كبيرة.`,
      impact: {
        cns: "منخفض",
        joints: "منخفض",
        local_muscle: "منخفض",
        recovery_days: 0.5
      },
      coaching_tip: "يمكن استخدام هذا الأسلوب 2-3 مرات أسبوعيًا لكل عضلة دون قلق."
    },
    medium: {
      title: `إجهاد متوسط: ${name}`,
      explanation: `${name} يولد إجهادًا متوسطًا يتراكم مع الوقت. رغم أنه قابل للإدارة بشكل منفصل، يجب مراقبة التكرار والحجم لمنع الإفراط.`,
      impact: {
        cns: "متوسط",
        joints: "متوسط",
        local_muscle: "متوسط",
        recovery_days: 1
      },
      coaching_tip: "استخدم هذا الأسلوب 1-2 مرة أسبوعيًا لكل عضلة، مع راحة كافية بين الجلسات."
    },
    high: {
      title: `إجهاد مرتفع: ${name}`,
      explanation: `${name} يولد إجهادًا كبيرًا، يضغط بشدة على الجهاز العصبي والنسيج العضلي المحلي. الاستخدام المتكرر دون استشفاء كاف يزيد من خطر الإصابات ويمكن أن يؤدي إلى الإفراط.`,
      impact: {
        cns: "عالي",
        joints: "متوسط",
        local_muscle: "عالي",
        recovery_days: 2
      },
      coaching_tip: "قلل الاستخدام إلى مرة واحدة أسبوعيًا لكل عضلة، وتجنب دمجه مع أساليب إجهاد مرتفعة أخرى."
    }
  };
  
  let base = baseExplanations[fatigueLevel] || baseExplanations.medium;
  
  // Customize based on intensifier characteristics
  if (name.toLowerCase().includes('rest-pause') || name.toLowerCase().includes('rest pause')) {
    base.explanation = `تدريب الراحة-التوقف يضغط بشدة على الجهاز العصبي بسبب جهود متكررة قريبة من الفشل مع فترات راحة قصيرة. هذا يولد إجهادًا محليًا وجهازيًا عاليًا.`;
    base.impact.cns = "عالي";
    base.impact.local_muscle = "عالي";
  } else if (name.toLowerCase().includes('myo-reps') || name.toLowerCase().includes('myoreps')) {
    base.explanation = `مايو-ريبس يولد إجهاد عضلي محلي شديد من خلال مجموعات تفعيل متكررة ومجموعات صغيرة، مع كونه أقل طلبًا على الجهاز العصبي والمفاصل.`;
    base.impact.local_muscle = "عالي";
    base.impact.cns = "متوسط";
    base.impact.joints = "منخفض";
  } else if (name.toLowerCase().includes('drop set')) {
    base.explanation = `مجموعات الإسقاط تخلق إجهادًا عاليًا من خلال الاستمرار الفوري بعد الفشل مع تقليل الحمل، مما يضغط بشدة على النسيج العضلي المحلي والهياكل الضامة.`;
    base.impact.local_muscle = "عالي";
    base.impact.joints = "عالي";
  } else if (name.toLowerCase().includes('cluster')) {
    base.explanation = `مجموعات العنقود تولد إجهادًا جهازيًا متوسطًا من خلال السماح باستشفاء قصير بين العناقيد مع الحفاظ على حمل عالي، مما يجعلها أكثر استدامة من المجموعات المستمرة.`;
    base.impact.cns = "متوسط";
    base.impact.local_muscle = "متوسط";
  } else if (name.toLowerCase().includes('tempo') || name.toLowerCase().includes('slow eccentric')) {
    base.explanation = `عمل الإيقاع والانقباضات البطيئة يضعان ضغطًا متزايدًا على الأنسجة الضامة والمفاصل من خلال وقت تحت التوتر المطول، مع توليد إجهاد عضلي محلي متوسط.`;
    base.impact.joints = "عالي";
    base.impact.local_muscle = "متوسط";
    base.impact.cns = "منخفض";
  } else if (name.toLowerCase().includes('isometric')) {
    base.explanation = `التمارين الثابتة تضغط بشكل أساسي على الأنسجة الضامة والمفاصل من خلال التحميل المستمر، مع متطلبات استقلابية وجهازية منخفضة نسبيًا.`;
    base.impact.joints = "عالي";
    base.impact.local_muscle = "منخفض";
    base.impact.cns = "منخفض";
  } else if (name.toLowerCase().includes('partial')) {
    base.explanation = `التكرارات الجزئية يمكن أن تقلل من ضغط المفاصل مع الحفاظ على توتر عضلي، مما يخلق إجهادًا محليًا متوسطًا مع متطلبات جهازية منخفضة.`;
    base.impact.joints = "منخفض";
    base.impact.local_muscle = "متوسط";
  }
  
  return base;
}

// =====================================================
// GLOBAL FATIGUE EXPLANATIONS
// =====================================================

const globalExplanations = {
  low: {
    en: {
      title: "Low Fatigue State",
      explanation: "You are in a fresh, recovered state with minimal accumulated fatigue. Training capacity is high, and you can push intensity without concern for overreaching.",
      impact: {
        cns: "low",
        joints: "low",
        local_muscle: "low",
        recovery_days: 0
      },
      coaching_tip: "This is the ideal state for high-intensity sessions, testing limits, and setting personal records."
    },
    ar: {
      title: "حالة إجهاد منخفض",
      explanation: "أنت في حالة منتعشة ومستشفية مع إجهاد متراكم قليل. قدرة التدريب عالية، ويمكنك الدفع بشدة دون قلق من الإفراط.",
      impact: {
        cns: "منخفض",
        joints: "منخفض",
        local_muscle: "منخفض",
        recovery_days: 0
      },
      coaching_tip: "هذه هي الحالة المثالية لجلسات عالية الكثافة واختبار الحدود وتحطيم الأرقام الشخصية."
    }
  },
  medium: {
    en: {
      title: "Moderate Fatigue Accumulation",
      explanation: "Fatigue is accumulating but remains manageable. Recovery between sessions is important, and you should monitor volume and intensity to prevent overreaching.",
      impact: {
        cns: "medium",
        joints: "medium",
        local_muscle: "medium",
        recovery_days: 1
      },
      coaching_tip: "Continue training but prioritize quality over quantity. Consider deloading if fatigue continues to increase."
    },
    ar: {
      title: "تراكم إجهاد متوسط",
      explanation: "الإجهاد يتراكم لكنه يبقى قابلاً للإدارة. الاستشفاء بين الجلسات مهم، ويجب مراقبة الحجم والشدة لمنع الإفراط.",
      impact: {
        cns: "متوسط",
        joints: "متوسط",
        local_muscle: "متوسط",
        recovery_days: 1
      },
      coaching_tip: "استمر في التدريب لكن أعطِ الأولوية للجودة على الكمية. فكر في تقليل الحمل إذا استمر الإجهاد في الزيادة."
    }
  },
  high: {
    en: {
      title: "High Fatigue - Overreaching Risk",
      explanation: "Fatigue has accumulated significantly. The nervous system, joints, and local muscle tissue are under stress. Continuing to push intensity without adequate recovery increases injury risk and may lead to burnout.",
      impact: {
        cns: "high",
        joints: "high",
        local_muscle: "high",
        recovery_days: 2
      },
      coaching_tip: "Immediate deload or rest period recommended. Focus on active recovery, sleep, and nutrition. Resume training only when fatigue levels decrease."
    },
    ar: {
      title: "إجهاد عالي - خطر الإفراط",
      explanation: "الإجهاد تراكم بشكل كبير. الجهاز العصبي والمفاصل والنسيج العضلي المحلي تحت ضغط. الاستمرار في الدفع بشدة دون استشفاء كاف يزيد من خطر الإصابات وقد يؤدي إلى الإرهاق.",
      impact: {
        cns: "عالي",
        joints: "عالي",
        local_muscle: "عالي",
        recovery_days: 2
      },
      coaching_tip: "يُنصح بتقليل الحمل أو فترة راحة فورية. ركز على الاستشفاء النشط والنوم والتغذية. استأنف التدريب فقط عندما تنخفض مستويات الإجهاد."
    }
  }
};

// =====================================================
// MAIN FUNCTION
// =====================================================

async function main() {
  const client = new Client(dbConfig);
  
  try {
    console.log('🔌 Connecting to database...');
    await client.connect();
    console.log('✅ Connected to database');
    
    let totalInserted = 0;
    let totalSkipped = 0;
    
    // =====================================================
    // STEP 1: Generate explanations for intensifiers
    // =====================================================
    console.log('\n📖 Step 1: Generating intensifier fatigue explanations...');
    
    const intensifiersResult = await client.query(`
      SELECT id, name, fatigue_cost, short_desc, how_to
      FROM intensifier_knowledge
      WHERE status = 'approved'
      ORDER BY name
    `);
    
    const intensifiers = intensifiersResult.rows;
    console.log(`📊 Found ${intensifiers.length} approved intensifiers`);
    
    for (const intensifier of intensifiers) {
      const fatigueLevel = mapFatigueCostToLevel(intensifier.fatigue_cost);
      
      // Generate English explanation
      const enExplanation = generateEnglishIntensifierExplanation(intensifier, fatigueLevel);
      
      // Generate Arabic explanation
      const arExplanation = generateArabicIntensifierExplanation(intensifier, fatigueLevel);
      
      // Insert English
      try {
        const enResult = await client.query(`
          INSERT INTO fatigue_explanations (
            entity_type, entity_id, fatigue_level, language,
            title, explanation, impact, coaching_tip
          )
          VALUES ($1, $2, $3, $4, $5, $6, $7::jsonb, $8)
          ON CONFLICT (entity_type, entity_id, fatigue_level, language) DO NOTHING
        `, [
          'intensifier',
          intensifier.id,
          fatigueLevel,
          'en',
          enExplanation.title,
          enExplanation.explanation,
          JSON.stringify(enExplanation.impact),
          enExplanation.coaching_tip
        ]);
        
        if (enResult.rowCount > 0) {
          totalInserted++;
        } else {
          totalSkipped++;
        }
      } catch (error) {
        console.error(`❌ Error inserting EN explanation for ${intensifier.name}:`, error.message);
      }
      
      // Insert Arabic
      try {
        const arResult = await client.query(`
          INSERT INTO fatigue_explanations (
            entity_type, entity_id, fatigue_level, language,
            title, explanation, impact, coaching_tip
          )
          VALUES ($1, $2, $3, $4, $5, $6, $7::jsonb, $8)
          ON CONFLICT (entity_type, entity_id, fatigue_level, language) DO NOTHING
        `, [
          'intensifier',
          intensifier.id,
          fatigueLevel,
          'ar',
          arExplanation.title,
          arExplanation.explanation,
          JSON.stringify(arExplanation.impact),
          arExplanation.coaching_tip
        ]);
        
        if (arResult.rowCount > 0) {
          totalInserted++;
        } else {
          totalSkipped++;
        }
      } catch (error) {
        console.error(`❌ Error inserting AR explanation for ${intensifier.name}:`, error.message);
      }
    }
    
    console.log(`✅ Processed ${intensifiers.length} intensifiers`);
    
    // =====================================================
    // STEP 2: Generate global fatigue explanations
    // =====================================================
    console.log('\n📖 Step 2: Generating global fatigue explanations...');
    
    for (const [level, explanations] of Object.entries(globalExplanations)) {
      // Insert English
      try {
        const enResult = await client.query(`
          INSERT INTO fatigue_explanations (
            entity_type, entity_id, fatigue_level, language,
            title, explanation, impact, coaching_tip
          )
          VALUES ($1, $2, $3, $4, $5, $6, $7::jsonb, $8)
          ON CONFLICT (entity_type, entity_id, fatigue_level, language) DO NOTHING
        `, [
          'global',
          null,
          level,
          'en',
          explanations.en.title,
          explanations.en.explanation,
          JSON.stringify(explanations.en.impact),
          explanations.en.coaching_tip
        ]);
        
        if (enResult.rowCount > 0) {
          totalInserted++;
        } else {
          totalSkipped++;
        }
      } catch (error) {
        console.error(`❌ Error inserting EN global explanation for ${level}:`, error.message);
      }
      
      // Insert Arabic
      try {
        const arResult = await client.query(`
          INSERT INTO fatigue_explanations (
            entity_type, entity_id, fatigue_level, language,
            title, explanation, impact, coaching_tip
          )
          VALUES ($1, $2, $3, $4, $5, $6, $7::jsonb, $8)
          ON CONFLICT (entity_type, entity_id, fatigue_level, language) DO NOTHING
        `, [
          'global',
          null,
          level,
          'ar',
          explanations.ar.title,
          explanations.ar.explanation,
          JSON.stringify(explanations.ar.impact),
          explanations.ar.coaching_tip
        ]);
        
        if (arResult.rowCount > 0) {
          totalInserted++;
        } else {
          totalSkipped++;
        }
      } catch (error) {
        console.error(`❌ Error inserting AR global explanation for ${level}:`, error.message);
      }
    }
    
    console.log(`✅ Generated global explanations for 3 fatigue levels`);
    
    // =====================================================
    // STEP 3: Final statistics
    // =====================================================
    console.log('\n📊 Final Statistics:');
    
    const statsResult = await client.query(`
      SELECT 
        language,
        entity_type,
        fatigue_level,
        COUNT(*) as count
      FROM fatigue_explanations
      GROUP BY language, entity_type, fatigue_level
      ORDER BY language, entity_type, fatigue_level
    `);
    
    console.table(statsResult.rows);
    
    const totalResult = await client.query(`
      SELECT 
        language,
        COUNT(*) as total
      FROM fatigue_explanations
      GROUP BY language
      ORDER BY language
    `);
    
    console.log('\n📈 Total by Language:');
    console.table(totalResult.rows);
    
    console.log(`\n✅ Fatigue explanation generation complete!`);
    console.log(`   - Total inserted: ${totalInserted}`);
    console.log(`   - Total skipped (already exists): ${totalSkipped}`);
    
    // =====================================================
    // STEP 4: Sample explanations
    // =====================================================
    console.log('\n📝 Sample Explanations:');
    
    // Sample intensifier explanation (English)
    const sampleIntensifierEn = await client.query(`
      SELECT fe.*, ik.name as intensifier_name
      FROM fatigue_explanations fe
      LEFT JOIN intensifier_knowledge ik ON ik.id = fe.entity_id
      WHERE fe.entity_type = 'intensifier'
        AND fe.language = 'en'
        AND fe.fatigue_level = 'high'
      LIMIT 1
    `);
    
    if (sampleIntensifierEn.rows.length > 0) {
      const sample = sampleIntensifierEn.rows[0];
      console.log(`\n   Intensifier (EN): ${sample.intensifier_name}`);
      console.log(`   Title: ${sample.title}`);
      console.log(`   Explanation: ${sample.explanation}`);
      console.log(`   Impact: ${JSON.stringify(sample.impact)}`);
      console.log(`   Tip: ${sample.coaching_tip}`);
    }
    
    // Sample intensifier explanation (Arabic)
    const sampleIntensifierAr = await client.query(`
      SELECT fe.*, ik.name as intensifier_name
      FROM fatigue_explanations fe
      LEFT JOIN intensifier_knowledge ik ON ik.id = fe.entity_id
      WHERE fe.entity_type = 'intensifier'
        AND fe.language = 'ar'
        AND fe.fatigue_level = 'high'
      LIMIT 1
    `);
    
    if (sampleIntensifierAr.rows.length > 0) {
      const sample = sampleIntensifierAr.rows[0];
      console.log(`\n   Intensifier (AR): ${sample.intensifier_name}`);
      console.log(`   Title: ${sample.title}`);
      console.log(`   Explanation: ${sample.explanation}`);
      console.log(`   Impact: ${JSON.stringify(sample.impact)}`);
      console.log(`   Tip: ${sample.coaching_tip}`);
    }
    
    // Sample global explanation (English)
    const sampleGlobalEn = await client.query(`
      SELECT *
      FROM fatigue_explanations
      WHERE entity_type = 'global'
        AND language = 'en'
        AND fatigue_level = 'high'
      LIMIT 1
    `);
    
    if (sampleGlobalEn.rows.length > 0) {
      const sample = sampleGlobalEn.rows[0];
      console.log(`\n   Global (EN): ${sample.fatigue_level}`);
      console.log(`   Title: ${sample.title}`);
      console.log(`   Explanation: ${sample.explanation}`);
      console.log(`   Tip: ${sample.coaching_tip}`);
    }
    
    // Sample global explanation (Arabic)
    const sampleGlobalAr = await client.query(`
      SELECT *
      FROM fatigue_explanations
      WHERE entity_type = 'global'
        AND language = 'ar'
        AND fatigue_level = 'high'
      LIMIT 1
    `);
    
    if (sampleGlobalAr.rows.length > 0) {
      const sample = sampleGlobalAr.rows[0];
      console.log(`\n   Global (AR): ${sample.fatigue_level}`);
      console.log(`   Title: ${sample.title}`);
      console.log(`   Explanation: ${sample.explanation}`);
      console.log(`   Tip: ${sample.coaching_tip}`);
    }
    
  } catch (error) {
    console.error('❌ Error:', error);
    process.exit(1);
  } finally {
    await client.end();
    console.log('\n🔌 Database connection closed');
  }
}

// Run if called directly
if (require.main === module) {
  main().catch(console.error);
}

module.exports = {
  generateEnglishIntensifierExplanation,
  generateArabicIntensifierExplanation,
  mapFatigueCostToLevel
};