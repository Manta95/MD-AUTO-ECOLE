CREATE TABLE IF NOT EXISTS `md_autoecole_licenses` (
    `id` INT(11) NOT NULL AUTO_INCREMENT,
    `identifier` VARCHAR(60) NOT NULL,
    `type` VARCHAR(20) NOT NULL,
    `date` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `status` VARCHAR(20) NOT NULL DEFAULT 'granted',
    PRIMARY KEY (`id`),
    UNIQUE KEY `unique_license` (`identifier`, `type`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
